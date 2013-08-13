require 'helper'
require_relative '../output/out_forest_test'

class ForestTestOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
tag foo.bar
tagfield ttt
prefix fixed:
suffix :end
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::ForestTestOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'foo.bar', d.instance.tag
    assert_equal 'fixed:', d.instance.prefix
    assert_equal ':end', d.instance.suffix
  end

  def test_emit
    d = create_driver
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.run do
      d.emit({'msg' => 'xyz 123', 'alt' => 'aaa bbb ccc'}, time)
      d.emit({'msg' => 'xyz 456', 'alt' => 'aaa bbb ccc ddd'}, time)
    end
    emits = d.emits
    assert_equal 2, emits.length

    assert_equal 'foo.bar', emits[0][0]
    assert_equal time, emits[0][1]
    assert_equal 'fixed:xyz 123:end', emits[0][2]['msg']
    assert_equal 'aaa bbb ccc', emits[0][2]['alt']
    assert_equal 'test', emits[0][2]['ttt']

    assert_equal 'foo.bar', emits[1][0]
    assert_equal time, emits[1][1]
    assert_equal 'fixed:xyz 456:end', emits[1][2]['msg']
    assert_equal 'aaa bbb ccc ddd', emits[1][2]['alt']
    assert_equal 'test', emits[1][2]['ttt']
  end

  def test_emit1
    d = create_driver
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.run do
      d.emit({'msg' => 'xyz 123', 'alt' => 'aaa bbb ccc'}, time)
      d.tag = 'test2'
      d.emit({'msg' => 'xyz 456', 'alt' => 'aaa bbb ccc ddd'}, time)
    end
    emits = d.emits
    assert_equal 2, emits.length

    assert_equal 'foo.bar', emits[0][0]
    assert_equal time, emits[0][1]
    assert_equal 'fixed:xyz 123:end', emits[0][2]['msg']
    assert_equal 'aaa bbb ccc', emits[0][2]['alt']
    assert_equal 'test', emits[0][2]['ttt']
    assert_nil emits[0][2]['not_started']

    assert_equal 'foo.bar', emits[1][0]
    assert_equal time, emits[1][1]
    assert_equal 'fixed:xyz 456:end', emits[1][2]['msg']
    assert_equal 'aaa bbb ccc ddd', emits[1][2]['alt']
    assert_equal 'test2', emits[1][2]['ttt']
    assert_nil emits[1][2]['not_started']
  end

  def test_emit2
    d = create_driver
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.run do
      d.emit({'msg' => 'xyz 123', 'alt' => 'aaa bbb ccc'}, time)
    end
    d.tag = 'test2'
    d.run do
      d.emit({'msg' => 'xyz 456', 'alt' => 'aaa bbb ccc ddd'}, time)
    end
    emits = d.emits
    assert_equal 2, emits.length

    assert_equal 'foo.bar', emits[0][0]
    assert_equal time, emits[0][1]
    assert_equal 'fixed:xyz 123:end', emits[0][2]['msg']
    assert_equal 'aaa bbb ccc', emits[0][2]['alt']
    assert_equal 'test', emits[0][2]['ttt']
    assert_nil emits[0][2]['not_started']

    assert_equal 'foo.bar', emits[1][0]
    assert_equal time, emits[1][1]
    assert_equal 'fixed:xyz 456:end', emits[1][2]['msg']
    assert_equal 'aaa bbb ccc ddd', emits[1][2]['alt']
    assert_equal 'test2', emits[1][2]['ttt']
    assert_nil emits[1][2]['not_started']
  end
end
