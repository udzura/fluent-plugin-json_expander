class Fluent::EchoPoolOutput < Fluent::Output
  class << self
    def echopool
      @echopool ||= []
    end
  end

  Fluent::Plugin.register_output('echopool', self)

  config_param :message, :string

  def emit(tag, es, chain)
    es.each {|time, record|
      self.class.echopool.push({
        message: @message,
        record:  record,
        tag:     tag
      })
    }
    chain.next
  end
end
