class Fluent::ForestTestOutput < Fluent::Output
  Fluent::Plugin.register_output('forest_test', self)

  config_param :key_name, :string, :default => 'msg'
  config_param :tag
  config_param :prefix, :string, :default => ''
  config_param :suffix, :string, :default => ''
  config_param :tagfield, :string, :default => nil

  def configure(conf)
    super
  end

  def emit(tag, es, chain)
    es.each {|time, record|
      r = record.merge({@key_name => @prefix + record[@key_name] + @suffix})
      if @tagfield
        r[@tagfield] = tag
      end
      Fluent::Engine.emit(@tag, time, r)
    }
    chain.next
  end
end
