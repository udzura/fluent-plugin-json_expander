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

    templates = conf.elements.select{|e| e.name == 'template' }
    if templates.size != 1
      raise Fluent::ConfigError, "Just 1 template must be contained"
    end

    @template = templates.first
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
      output = new_output(record)
      if output
        dup_es = Fluent::ArrayEventStream.new([[time, record]])
        null_chain = Fluent::NullOutputChain.instance
        output.emit(tag, dup_es, null_chain)
      end
    }
    chain.next
  end

  private

  def new_output(data)
    o = nil
    t = @template
    begin
      @mutex.synchronize do
        if e = expand_elm(t, data)
          o = Fluent::Plugin.new_output(@subtype)
          o.configure(e)
          o.start

          @outputs.push(o)
        end
      end

      log.info "[out_json_expand] Expanded new output: #{@subtype}"
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

    return o
  end

  SCAN_DATA_RE = /\$\{data\[(?:[_a-zA-Z][_a-zA-Z0-9]*)\]\}/
  SCAN_KEY_NAME_RE = /\[([_a-zA-Z][_a-zA-Z0-9]*)\]/

  def expand_elm(template, data)
    attr = {}
    template.each do |k, v|
      v = v.gsub(SCAN_DATA_RE) do |matched|
        key_matched = matched.scan(SCAN_KEY_NAME_RE)[0]
        if !key_matched or !key_matched[0]
          raise(Fluent::ConfigError, "[BUG] data matched in template, but could not find key name")
        end
        if @handle_empty_as_error
          k = key_matched[0]
          data[k] || mark_errored(k, data)
        else
          data[key_matched[0]] || ""
        end
      end
      attr[k] = v
    end
    # Expand recursively
    sub_elms = template.elements.map {|e| expand_elm(data) }

    if @mark_errored
      nil
    else
      Fluent::Config::Element.new('instance', '', attr, sub_elms)
    end
  end

  def mark_errored(k, data)
    log.error "Could not find value for `#{k}' in data #{data.inspect}, Fluentd skips this"
    @mark_errored = true
  end
end
