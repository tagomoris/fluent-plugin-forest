class Fluent::ForestOutput < Fluent::MultiOutput
  Fluent::Plugin.register_output('forest', self)

  config_param :subtype, :string
  config_param :remove_prefix, :string, :default => nil
  config_param :add_prefix, :string, :default => nil
  config_param :hostname, :string, :default => `hostname`.chomp
  config_param :escape_tag_separator, :string, :default => '_'

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
      # read and throw away to supress unread configuration warning
      touch_recursive(element)

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

  def touch_recursive(e)
    e.keys.each do |k|
      e[k]
    end
    e.elements.each do |child|
      touch_recursive(child)
    end
  end

  def shutdown
    super
    @mapping.values.each do |output|
      output.shutdown
    end
  end

  def parameter(tag, e, name = 'instance', arg = '')
    tag_parts = tag.split('.') 
    escaped_tag = tag.gsub('.', @escape_tag_separator)
    pairs = {}
    e.each do |k,v|
      v = v.gsub(/__TAG_PARTS\[(?<idx>-?[0-9]+(?:\.\.\.?-?[0-9]+)?)\]__|\$\{tag_parts\[(?<idx>-?[0-9]+(?:\.\.\.?-?[0-9]+)?\])\}/) do
        idx = $~[:idx]
        if idx =~ /(?<start>-?[0-9]+)\.\.(?<rangetype>\.)?(?<end>-?[0-9]+)/
          range_start = $~[:start].to_i
          rangetype = $~[:rangetype]
          range_end = $~[:end].to_i
          range = (rangetype)? Range.new(range_start, range_end-1): Range.new(range_start, range_end)
          if tag_parts[range]
            tag_parts[range].join(".")
          else
            $log.warn "out_forest: missing placeholder. tag:#{tag} placeholder:#{idx} conf:#{k} #{v}"
            nil
          end
        else
          $log.warn "out_forest: missing placeholder. tag:#{tag} placeholder:#{idx} conf:#{k} #{v}" unless tag_parts[idx.to_i]
          tag_parts[idx.to_i]
        end
      end
      v = v.gsub('__ESCAPED_TAG__', escaped_tag).gsub('${escaped_tag}', escaped_tag)
      pairs[k] = v.gsub('__TAG__', tag).gsub('${tag}', tag).gsub('__HOSTNAME__', @hostname).gsub('${hostname}', @hostname)
    end
    elements = e.elements.map do |child|
      parameter(tag, child, child.name, child.arg)
    end
    Fluent::Config::Element.new(name, arg, pairs, elements)
  end

  def spec(tag)
    conf = Fluent::Config::Element.new('instance', '', {}, [])
    conf = parameter(tag, @template) + conf if @template # a + b -> b.merge(a) (see: fluentd/lib/fluent/config.rb)
    @cases.each do |m,e|
      if m.match(tag)
        matched_case = parameter(tag, e)

        matched_case.elements.each { |case_child|
          unless case_child.arg.empty?
            conf.elements.delete_if { |conf_child|
              conf_child.name == case_child.name && conf_child.arg == case_child.arg
            }
          end
        }

        conf = matched_case + conf
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
