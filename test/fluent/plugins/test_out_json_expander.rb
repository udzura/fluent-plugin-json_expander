class JsonExpanderOutputTest < Test::Unit::TestCase
  CONFIG = <<-FLUENT
subtype echo
remove_prefix test
add_prefix fluentd
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
end
