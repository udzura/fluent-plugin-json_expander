require 'fluent/plugin/testing/out_echopool'

class JsonExpanderOutputTest < Test::Unit::TestCase
  CONFIG = <<-FLUENT
subtype echopool
remove_prefix test
add_prefix hello
<template>
  message Hello, ${data[first_name]} ${data[last_name]}!
</template>
  FLUENT

  def setup
    Fluent::Test.setup
  end

  def create_driver(conf = CONFIG, tag='test.default')
    Fluent::Test::OutputTestDriver.new(Fluent::JsonExpanderOutput, tag).configure(conf)
  end

  def test_configure
    assert_nothing_raised { d = create_driver }
  end

  def test_emit
    d = create_driver
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.tag = 'test.default'
    d.run {
      d.emit({'first_name' => "Yukihiro", 'last_name' => "Matsumoto"}, time)
    }

    assert { Fluent::EchoPoolOutput.echopool.size == 1 }
  end
end
