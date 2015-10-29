class Fluent::JsonExpanderOutput < Fluent::MultiOutput
  Fluent::Plugin.register_output('json_expander', self)

  config_param :subtype,       :string
  config_param :remove_prefix, :string, :default => nil
  config_param :add_prefix,    :string, :default => nil

  config_param :delete_used_key,       :bool, :default => false
  config_param :handle_empty_as_error, :bool, :default => false

  attr_reader :outputs

  # Define `log` method for v0.10.42 or earlier
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  def configure(conf)
    super

    if @remove_prefix
      @removed_prefix_string = @remove_prefix + '.'
      @removed_length = @removed_prefix_string.length
    end
    if @add_prefix
      @added_prefix_string = @add_prefix + '.'
    end

    @outputs = []
    @mutex = Mutex.new
    @mappings = {}
    @invalid_mapping_keys = []

    templates = conf.elements.select{|e| e.name == 'template' }
    if templates.size != 1
      raise Fluent::ConfigError, "Just 1 template must be contained"
    end

    @template = templates.first
    @expand_target_keys = scan_keys(@template)
  end

  def emit(tag, es, chain)
    if @remove_prefix and
        ((tag.start_with?(@removed_prefix_string) and tag.length > @removed_length) or tag == @remove_prefix)
      tag = tag[@removed_length..-1]
    end
    if @add_prefix
      tag = tag.empty? ? @add_prefix : (@added_prefix_string + tag)
    end

    es.each {|time, record|
      output, new_record = *new_output(record)
      if output
        dup_es = Fluent::ArrayEventStream.new([[time, new_record]])
        null_chain = Fluent::NullOutputChain.instance
        output.emit(tag, dup_es, null_chain)
      end
    }
    chain.next
  end

  def shutdown
    super
    @mappings.values.each do |output|
      output.shutdown
    end
    @mappings.clear
  end

  private

  SCAN_DATA_RE = /\$\{data\[([_a-zA-Z][_a-zA-Z0-9]*)\]\}/
  def scan_keys(elm)
    elm.inject([]) { |dst, (attr, value)|
      dst.concat(value.scan(SCAN_DATA_RE).flatten)
    }.sort.uniq
  end

  def to_mapping_key(data)
    data.select{|k, _| @expand_target_keys.include? k }
      .to_a
      .sort_by(&:first)
      .flatten
      .join("::")
  end

  def new_output(data)
    o = nil
    t = @template
    map_key = to_mapping_key(data)
    if @invalid_mapping_keys.include?(map_key)
      return o, data
    end

    begin
      o = @mappings[map_key]
      if o
        if @delete_used_key
          @expand_target_keys.each{|k| data.delete(k) }
        end
      else
        @mutex.synchronize do
          e, data = expand_elm(t, data)
          if e
            o = Fluent::Plugin.new_output(@subtype)
            o.configure(e)
            o.start

            @outputs.push(o)
            @mappings[map_key] = o
          end
        end

        log.info "[out_json_expand] Expanded new output: #{@subtype}"
      end
    rescue Fluent::ConfigError => e
      log.error "failed to configure sub output #{@subtype}: #{e.message}"
      log.error e.backtrace.join("\n")
      log.error "Cannot output messages with data #{data.inspect}"
      o = nil
    rescue StandardError => e
      log.error "failed to configure/start sub output #{@subtype}: #{e.message}"
      log.error e.backtrace.join("\n")
      log.error "Cannot output messages with data #{data.inspect}"
      o = nil
    end

    unless o
      @invalid_mapping_keys << map_key
    end

    return o, data
  end

  GSUB_DATA_RE = /\$\{data\[(?:[_a-zA-Z][_a-zA-Z0-9]*)\]\}/
  SCAN_KEY_NAME_RE = /\[([_a-zA-Z][_a-zA-Z0-9]*)\]/

  def expand_elm(template, data)
    attr = {}
    template.each do |k, v|
      v = v.gsub(GSUB_DATA_RE) do |matched|
        key_matched = matched.scan(SCAN_KEY_NAME_RE)[0]
        if !key_matched or !key_matched[0]
          raise(Fluent::ConfigError, "[BUG] data matched in template, but could not find key name")
        end
        target = key_matched[0]
        if @delete_used_key
          data.delete(target) || on_empty_data(target, data)
        else
          data[target] || on_empty_data(target, data)
        end
      end
      attr[k] = v
    end
    # Expand recursively
    sub_elms = template.elements.map {|e| expand_elm(data) }

    if @mark_errored
      return nil, nil
    else
      return Fluent::Config::Element.new('instance', '', attr, sub_elms), data
    end
  end

  def on_empty_data(k, data)
    if @handle_empty_as_error
      log.error "Could not find value for `#{k}' in data #{data.inspect}, Fluentd skips this"
      @mark_errored = true
    end
    ""
  end
end
