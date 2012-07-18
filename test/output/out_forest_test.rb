require 'fluent/test'
class Fluent::ForestTestOutput < Fluent::Output
  Fluent::Plugin.register_output('forest_test', self)

  config_param :key_name, :string, :default => 'msg'
  config_param :tag
  config_param :prefix, :string, :default => ''
  config_param :suffix, :string, :default => ''
  config_param :tagfield, :string, :default => nil

  attr_accessor :started, :stopped

  def configure(conf)
    super

    if @tag == 'raise.error'
      raise Fluent::ConfigError, "specified to raise.error"
    end
  end

  def start
    super
    @started = true
  end

  def shutdown
    super
    @stopped = true
  end

  def emit(tag, es, chain)
    es.each {|time, record|
      r = record.merge({@key_name => @prefix + record[@key_name] + @suffix})
      unless @started
        r = r.merge({'not_started' => true})
      end
      if @tagfield
        r[@tagfield] = tag
      end
      Fluent::Engine.emit(@tag, time, r)
    }
    chain.next
  end
end
