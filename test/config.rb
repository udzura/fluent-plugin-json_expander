require 'test/unit'
require 'test/unit/rr'
require 'power_assert'

require 'fluent/test'
case
when ENV.has_key?('LOG2STDOUT')
  $log = Fluent::Log.new(STDOUT, Fluent::Log::LEVEL_TRACE)
  $DEBUG_LOG2STDOUT = true
when ! ENV.has_key?('VERBOSE')
  nulllogger = Object.new
  nulllogger.instance_eval {|obj|
    def method_missing(method, *args)
      # pass
    end
  }
  $log = nulllogger
end

require 'fluent/plugin/out_json_expander'
