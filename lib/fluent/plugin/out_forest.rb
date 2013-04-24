class Fluent::ForestOutput < Fluent::MultiOutput
  Fluent::Plugin.register_output('forest', self)

  config_param :subtype, :string
  config_param :remove_prefix, :string, :default => nil
  config_param :add_prefix, :string, :default => nil
  config_param :hostname, :string, :default => `hostname`.chomp

  attr_reader :outputs

  def configure(conf)
    super

    if @remove_prefix
      @removed_prefix_string = @remove_prefix + '.'
      @removed_length = @removed_prefix_string.length
    end
    if @add_prefix
      @added_prefix_string = @add_prefix + '.'
    end

    @mapping = {} # tag => output
    @outputs = []
    @mutex = Mutex.new

    @template = nil
    @parameter = nil
    @cases = []

    conf.elements.each do |element|
      element.keys.each do |k|
        # read and throw away to supress unread configuration warning
        element[k]
      end
      case element.name
      when 'template'
        @template = element
      when 'case'
        matcher = Fluent::GlobMatchPattern.new(element.arg)
        @cases.push([matcher, element])
      end
    end

    self
  end

  def shutdown
    super
    @mapping.values.each do |output|
      output.shutdown
    end
  end

  def parameter(tag, e)
    pairs = {}
    e.each do |k,v|
      pairs[k] = v.gsub('__TAG__', tag).gsub('${tag}', tag).gsub('__HOSTNAME__', @hostname).gsub('${hostname}', @hostname)
    end
    Fluent::Config::Element.new('instance', '', pairs, [])
  end

  def spec(tag)
    conf = Fluent::Config::Element.new('instance', '', {}, [])
    conf = parameter(tag, @template) + conf if @template # a + b -> b.merge(a) (see: fluentd/lib/fluent/config.rb)
    @cases.each do |m,e|
      if m.match(tag)
        conf = parameter(tag, e) + conf
        break
      end
    end
    conf
  end

  def plant(tag)
    output = nil
    begin
      @mutex.synchronize {
        output = @mapping[tag]
        unless output
          output = Fluent::Plugin.new_output(@subtype)
          output.configure(spec(tag))
          output.start
          @mapping[tag] = output
          @outputs.push(output)
        end
      }
      $log.info "out_forest plants new output: #{@subtype} for tag '#{tag}'"
    rescue Fluent::ConfigError => e
      $log.error "failed to configure sub output #{@subtype}: #{e.message}"
      $log.error e.backtrace.join("\n")
      $log.error "Cannot output messages with tag '#{tag}'"
      output = nil
    rescue StandardError => e
      $log.error "failed to configure/start sub output #{@subtype}: #{e.message}"
      $log.error e.backtrace.join("\n")
      $log.error "Cannot output messages with tag '#{tag}'"
      output = nil
    end
    output
  end

  def emit(tag, es, chain)
    if @remove_prefix and
        ( (tag.start_with?(@removed_prefix_string) and tag.length > @removed_length) or tag == @remove_prefix)
      tag = tag[@removed_length..-1]
    end
    if @add_prefix
      tag = if tag.length > 0
              @added_prefix_string + tag
            else
              @add_prefix
            end
    end

    output = @mapping[tag]
    unless output
      output = plant(tag)
    end
    if output
      output.emit(tag, es, chain)
    else
      chain.next
    end
  end
end
