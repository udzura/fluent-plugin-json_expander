require 'fluent/plugin/testing/out_echopool'

class JsonExpanderOutputTest < Test::Unit::TestCase
  CONFIG = <<-FLUENT
subtype echopool
remove_prefix test
add_prefix hello
%s
<template>
  message Hello, ${data[first_name]} ${data[last_name]}!
</template>
  FLUENT

  def get_config(attr={})
    CONFIG % attr.inject("") do |dst, (k, v)|
      dst << [k, v].join(" ")
    end
  end

  def setup
    Fluent::Test.setup
  end

  def cleanup
    Fluent::EchoPoolOutput.echopool.clear
  end

  def create_driver(conf: get_config, tag: 'test.default')
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
    emit0 = Fluent::EchoPoolOutput.echopool[0]
    assert { emit0[:message] == "Hello, Yukihiro Matsumoto!" }
    assert { emit0[:record]  == {"first_name"=>"Yukihiro", "last_name"=>"Matsumoto"} }
    assert { emit0[:tag]     == "hello.default" }
  end

  def test_emit_many_times
    d = create_driver
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.tag = 'test.default'
    d.run {
      d.emit({'first_name' => "Yukihiro", 'last_name' => "Matsumoto"}, time)
      d.emit({'first_name' => "Foo",  'last_name' => "Bar"}, time)
      d.emit({'first_name' => "Foo2", 'last_name' => "Bar"}, time)
      d.emit({'first_name' => "Foo3", 'last_name' => "Bar"}, time)
    }

    assert { Fluent::EchoPoolOutput.echopool.size == 4 }
    assert { Fluent::EchoPoolOutput.echopool[0][:message] == "Hello, Yukihiro Matsumoto!" }
    assert { Fluent::EchoPoolOutput.echopool[1][:message] == "Hello, Foo Bar!" }
    assert { Fluent::EchoPoolOutput.echopool[2][:message] == "Hello, Foo2 Bar!" }
    assert { Fluent::EchoPoolOutput.echopool[3][:message] == "Hello, Foo3 Bar!" }
  end

  def test_with_delete_used_key
    d = create_driver(conf: get_config(delete_used_key: 'true'))
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.tag = 'test.default'
    d.run {
      d.emit({'first_name' => "Ryosuke", 'last_name' => "Matsumoto", "extra" => "arg"}, time)
    }

    assert { Fluent::EchoPoolOutput.echopool.size == 1 }
    emit0 = Fluent::EchoPoolOutput.echopool[0]
    assert { emit0[:message] == "Hello, Ryosuke Matsumoto!" }
    assert { emit0[:record]  == {"extra" => "arg"} }
    assert { emit0[:tag]     == "hello.default" }
  end

  def test_with_no_handle_empty_as_error
    d = create_driver(conf: get_config(handle_empty_as_error: 'false'))
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.tag = 'test.default'
    d.run {
      d.emit({'last_name' => "Matsumoto"}, time)
    }

    assert { Fluent::EchoPoolOutput.echopool.size == 1 }
    emit0 = Fluent::EchoPoolOutput.echopool[0]
    assert { emit0[:message] == "Hello,  Matsumoto!" }
    assert { emit0[:record]  == {"last_name"=>"Matsumoto"} }
    assert { emit0[:tag]     == "hello.default" }
  end

  def test_with_handle_empty_as_error
    d = create_driver(conf: get_config(handle_empty_as_error: 'true'))
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.tag = 'test.default'
    d.run {
      d.emit({'last_name' => "Matsumoto"}, time)
    }

    assert { Fluent::EchoPoolOutput.echopool.size == 0 }
  end
end
