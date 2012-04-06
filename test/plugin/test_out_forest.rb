require 'helper'
require_relative '../output/out_forest_test'

class ForestOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
subtype forest_test
remove_prefix test
<template>
  key_name f
  suffix !
</template>
<case foo.bar>
  prefix p1:
</case>
<case foo.*>
  prefix p2:
</case>
<case bar.**>
  prefix p3:
</case>
<case *>
  prefix p4:
</case>
<parameter>
  tag out.__TAG__  
</parameter>
  ]

  def create_driver(conf = CONFIG, tag='test.default')
    Fluent::Test::OutputTestDriver.new(Fluent::ForestOutput, tag).configure(conf)
  end

  def test_configure
    assert_nothing_raised { d = create_driver }
  end

  def test_emit
    d = create_driver
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.tag = 'test.first';  d.run { d.emit({'f' => "message 1"}, time) }
    d.tag = 'test.second'; d.run { d.emit({'f' => "message 2"}, time) }
    d.tag = 'test.foo.bar'; d.run { d.emit({'f' => "message 3"}, time) }
    d.tag = 'test.foo.baz'; d.run { d.emit({'f' => "message 4"}, time) }
    d.tag = 'test.bar';     d.run { d.emit({'f' => "message 5"}, time) }
    d.tag = 'test.baz';     d.run { d.emit({'f' => "message 6"}, time) }
    d.tag = 'test.foo.bar'; d.run { d.emit({'f' => "message 7"}, time) }
    d.tag = 'test.bar';     d.run { d.emit({'f' => "message 8"}, time) }

    emits = d.emits

    e = emits[0]
    assert_equal 'out.first', e[0]
    assert_equal time, e[1]
    assert_equal "p4:message 1!", e[2]['f']
    
    e = emits[1]
    assert_equal 'out.second', e[0]
    assert_equal time, e[1]
    assert_equal "p4:message 2!", e[2]['f']

    e = emits[2]
    assert_equal 'out.foo.bar', e[0]
    assert_equal time, e[1]
    assert_equal "p1:message 3!", e[2]['f']

    e = emits[3]
    assert_equal 'out.foo.baz', e[0]
    assert_equal time, e[1]
    assert_equal "p2:message 4!", e[2]['f']

    e = emits[4]
    assert_equal 'out.bar', e[0]
    assert_equal time, e[1]
    assert_equal "p3:message 5!", e[2]['f']

    e = emits[5]
    assert_equal 'out.baz', e[0]
    assert_equal time, e[1]
    assert_equal "p4:message 6!", e[2]['f']

    e = emits[6]
    assert_equal 'out.foo.bar', e[0]
    assert_equal time, e[1]
    assert_equal "p1:message 7!", e[2]['f']

    e = emits[7]
    assert_equal 'out.bar', e[0]
    assert_equal time, e[1]
    assert_equal "p3:message 8!", e[2]['f']
  end
end
