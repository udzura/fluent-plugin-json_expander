class Fluent::ForestOutput < Fluent::MultiOutput
  Fluent::Plugin.register_output('json_expander', self)

  config_param :subtype,         :string
  config_param :remove_prefix,   :string, :default => nil
  config_param :add_prefix,      :string, :default => nil
  config_param :delete_used_key, :bool,   :default => false

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
  end


  def emit(tag, es, chain)
    if @remove_prefix and
        ((tag.start_with?(@removed_prefix_string) and tag.length > @removed_length) or tag == @remove_prefix)
      tag = tag[@removed_length..-1]
    end
    if @add_prefix
      tag = tag.empty? ? (@added_prefix_string + tag) : @add_prefix
    end

    chain.next
  end
end
