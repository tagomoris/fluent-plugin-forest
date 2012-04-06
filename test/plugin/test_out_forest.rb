require 'helper'

class ForestOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::ForestOutput, tag).configure(conf)
  end

  def test_configure
  end

  def test_emit
  end
end
