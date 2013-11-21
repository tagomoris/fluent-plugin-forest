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
  tag out.__TAG__
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
  ]

  def create_driver(conf = CONFIG, tag='test.default')
    Fluent::Test::OutputTestDriver.new(Fluent::ForestOutput, tag).configure(conf)
  end

  def test_configure
    assert_nothing_raised { d = create_driver }
  end

  def test_spec
    d = create_driver %[
subtype hoge
<template>
  keyx xxxxxx
  keyy yyyyyy.__TAG__
  alt_key a
</template>
<case xx>
  keyz z1
  alt_key b
</case>
<case yy.**>
  keyz z2
  alt_key c
</case>
<case *>
  keyz z3
  alt_key d.__TAG__
</case>
    ]
    conf = d.instance.spec('xx')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.xx', conf['keyy']
    assert_equal 'z1', conf['keyz']
    assert_equal 'b', conf['alt_key']

    conf = d.instance.spec('yy')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.yy', conf['keyy']
    assert_equal 'z2', conf['keyz']
    assert_equal 'c', conf['alt_key']

    conf = d.instance.spec('yy.3')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.yy.3', conf['keyy']
    assert_equal 'z2', conf['keyz']
    assert_equal 'c', conf['alt_key']

    conf = d.instance.spec('zz')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.zz', conf['keyy']
    assert_equal 'z3', conf['keyz']
    assert_equal 'd.zz', conf['alt_key']
  end

  NESTED_CONF = %[
subtype hoge
<template>
  keyx xxxxxx
  keyy yyyyyy.__TAG__
  alt_key a
  <tagx>
    key xxx
  </tagx>
  <tagy>
    key yyy.__TAG__
  </tagy>
  <tag_with attr.foo>
    key bar
  </tag_with>
  <tag_with attr.foo>
    key dup
  </tag_with>
  <tag_with attr.foo>
    key dupdup
  </tag_with>
</template>
<case xx>
  keyz z1
  alt_key b
</case>
<case yy.**>
  keyz z2
  alt_key c
  <tagx>
    key not_overwrite
  </tagx>
  <tag_with attr.foo>
    key overwrite
  </tag_with>
  <tag_with attr.foo>
    key overwrite_dup
  </tag_with>
</case>
<case *>
  keyz z3
  alt_key d.__TAG__
  <tagz>
    <tagw>
      key www
    </tagw>
  </tagz>
  <tag_with attr.*>
    key not_overwrite
  </tag_with>
</case>
    ]

  def test_spec_nested_overwrite_attributes_only
    d = create_driver NESTED_CONF
    conf = d.instance.spec('xx')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.xx', conf['keyy']
    assert_equal 'z1', conf['keyz']
    assert_equal 'b', conf['alt_key']

    assert_equal 5, conf.elements.size

    assert_equal 'tagx', conf.elements[0].name
    assert_equal 'xxx', conf.elements[0]['key']

    assert_equal 'tagy', conf.elements[1].name
    assert_equal 'yyy.xx', conf.elements[1]['key']

    assert_equal 'tag_with', conf.elements[2].name
    assert_equal 'attr.foo', conf.elements[2].arg
    assert_equal 'bar', conf.elements[2]['key']

    assert_equal 'tag_with', conf.elements[3].name
    assert_equal 'attr.foo', conf.elements[3].arg
    assert_equal 'dup', conf.elements[3]['key']

    assert_equal 'tag_with', conf.elements[4].name
    assert_equal 'attr.foo', conf.elements[4].arg
    assert_equal 'dupdup', conf.elements[4]['key']
  end
  def test_spec_nested_overwrite_subsections_with_arg
    d = create_driver NESTED_CONF
    conf = d.instance.spec('yy')

    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.yy', conf['keyy']
    assert_equal 'z2', conf['keyz']
    assert_equal 'c', conf['alt_key']

    assert_equal 5, conf.elements.size

    assert_equal 'tagx', conf.elements[0].name
    assert_equal 'not_overwrite', conf.elements[0]['key']

    assert_equal 'tag_with', conf.elements[1].name
    assert_equal 'attr.foo', conf.elements[1].arg
    assert_equal 'overwrite', conf.elements[1]['key']

    assert_equal 'tag_with', conf.elements[2].name
    assert_equal 'attr.foo', conf.elements[2].arg
    assert_equal 'overwrite_dup', conf.elements[2]['key']

    assert_equal 'tagx', conf.elements[3].name
    assert_equal 'xxx', conf.elements[3]['key']

    assert_equal 'tagy', conf.elements[4].name
    assert_equal 'yyy.yy', conf.elements[4]['key']
  end

  def test_spec_nested_subsections_added
    d = create_driver NESTED_CONF
    conf = d.instance.spec('zz')

    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.zz', conf['keyy']
    assert_equal 'z3', conf['keyz']
    assert_equal 'd.zz', conf['alt_key']

    assert_equal 7, conf.elements.size

    assert_equal 'tagz', conf.elements[0].name
    assert_equal 1, conf.elements[0].elements.size
    assert_equal 'tagw', conf.elements[0].elements[0].name
    assert_equal 'www', conf.elements[0].elements[0]['key']

    assert_equal 'tag_with', conf.elements[1].name
    assert_equal 'attr.*', conf.elements[1].arg
    assert_equal 'not_overwrite', conf.elements[1]['key']

    assert_equal 'tagx', conf.elements[2].name
    assert_equal 'xxx', conf.elements[2]['key']

    assert_equal 'tagy', conf.elements[3].name
    assert_equal 'yyy.zz', conf.elements[3]['key']

    assert_equal 'tag_with', conf.elements[4].name
    assert_equal 'attr.foo', conf.elements[4].arg
    assert_equal 'bar', conf.elements[4]['key']

    assert_equal 'tag_with', conf.elements[5].name
    assert_equal 'attr.foo', conf.elements[5].arg
    assert_equal 'dup', conf.elements[5]['key']

    assert_equal 'tag_with', conf.elements[6].name
    assert_equal 'attr.foo', conf.elements[6].arg
    assert_equal 'dupdup', conf.elements[6]['key']
  end

  def test_spec_replace_tag_separator
    d = create_driver %[
subtype hoge
<template>
  keyx xxxxxx
  keyy yyyyyy.__ESCAPED_TAG__
</template>
<case xx.*>
  keyz zzzzzz.__ESCAPED_TAG__
  alt_key a
</case>
<case xx.**>
  keyz zzzzzz.${escaped_tag}
  alt_key b
</case>
    ]

    conf = d.instance.spec('xx.1')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.xx_1', conf['keyy']
    assert_equal 'zzzzzz.xx_1', conf['keyz']
    assert_equal 'a', conf['alt_key']

    conf = d.instance.spec('xx.1.2')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.xx_1_2', conf['keyy']
    assert_equal 'zzzzzz.xx_1_2', conf['keyz']
    assert_equal 'b', conf['alt_key']
  end

  def test_spec_replace_tag_separator_with_specified_char
    d = create_driver %[
subtype hoge
escape_tag_separator +
<template>
  keyx xxxxxx
  keyy yyyyyy.__ESCAPED_TAG__
</template>
<case xx.**>
  keyz zzzzzz.${escaped_tag}
</case>
    ]

    conf = d.instance.spec('xx.1')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.xx+1', conf['keyy']
    assert_equal 'zzzzzz.xx+1', conf['keyz']

    conf = d.instance.spec('xx.1.2')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.xx+1+2', conf['keyy']
    assert_equal 'zzzzzz.xx+1+2', conf['keyz']
  end

  def test_spec_split_tag_by_dot
    d = create_driver %[
subtype hoge
<template>
  keyx xxxxxx
  keyy yyyyyy.${tag_parts[0]}
  unknown_tag_parts bar.${tag_parts[999]}.__TAG_PARTS[999]__
</template>
<case xx.*>
  keyz zzzzzz.${tag_parts[0]}.${tag_parts[1]}
  alt_key a
</case>
<case xx.**>
  keyz zzzzzz.__TAG_PARTS[0]__.__TAG_PARTS[2]__
  alt_key b
</case>
    ]

    conf = d.instance.spec('xx.1')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.xx', conf['keyy']
    assert_equal 'zzzzzz.xx.1', conf['keyz']
    assert_equal 'bar..', conf['unknown_tag_parts']
    assert_equal 'a', conf['alt_key']

    conf = d.instance.spec('xx.1.2')
    assert_equal 'xxxxxx', conf['keyx']
    assert_equal 'yyyyyy.xx', conf['keyy']
    assert_equal 'zzzzzz.xx.2', conf['keyz']
    assert_equal 'b', conf['alt_key']
  end

  def test_spec_hostname
    d = create_driver %[
subtype hoge
hostname somehost.local
<template>
  keyx xxxxxx.__HOSTNAME__
  keyy yyyyyy.__TAG__
  alt_key a
</template>
<case xx>
  keyz z1
  alt_key b
</case>
<case yy.**>
  keyz z2
  alt_key c
</case>
<case *>
  keyz z3
  alt_key d.__TAG__.__HOSTNAME__
</case>
    ]
    conf = d.instance.spec('xx')
    assert_equal 'xxxxxx.somehost.local', conf['keyx']
    assert_equal 'yyyyyy.xx', conf['keyy']
    assert_equal 'z1', conf['keyz']
    assert_equal 'b', conf['alt_key']

    conf = d.instance.spec('yy')
    assert_equal 'xxxxxx.somehost.local', conf['keyx']
    assert_equal 'yyyyyy.yy', conf['keyy']
    assert_equal 'z2', conf['keyz']
    assert_equal 'c', conf['alt_key']

    conf = d.instance.spec('yy.3')
    assert_equal 'xxxxxx.somehost.local', conf['keyx']
    assert_equal 'yyyyyy.yy.3', conf['keyy']
    assert_equal 'z2', conf['keyz']
    assert_equal 'c', conf['alt_key']

    conf = d.instance.spec('zz')
    assert_equal 'xxxxxx.somehost.local', conf['keyx']
    assert_equal 'yyyyyy.zz', conf['keyy']
    assert_equal 'z3', conf['keyz']
    assert_equal 'd.zz.somehost.local', conf['alt_key']
  end

  def test_spec_real_hostname
    hostname = `hostname`.chomp
    d = create_driver %[
subtype hoge
<template>
  keyx xxxxxx.__HOSTNAME__
  keyy yyyyyy.__TAG__
  alt_key a
</template>
<case xx>
  keyz z1
  alt_key b
</case>
<case yy.**>
  keyz z2
  alt_key c
</case>
<case *>
  keyz z3
  alt_key d.${tag}.${hostname}
</case>
    ]
    conf = d.instance.spec('xx')
    assert_equal 'xxxxxx.' + hostname, conf['keyx']
    assert_equal 'yyyyyy.xx', conf['keyy']
    assert_equal 'z1', conf['keyz']
    assert_equal 'b', conf['alt_key']

    conf = d.instance.spec('yy')
    assert_equal 'xxxxxx.' + hostname, conf['keyx']
    assert_equal 'yyyyyy.yy', conf['keyy']
    assert_equal 'z2', conf['keyz']
    assert_equal 'c', conf['alt_key']

    conf = d.instance.spec('yy.3')
    assert_equal 'xxxxxx.' + hostname, conf['keyx']
    assert_equal 'yyyyyy.yy.3', conf['keyy']
    assert_equal 'z2', conf['keyz']
    assert_equal 'c', conf['alt_key']

    conf = d.instance.spec('zz')
    assert_equal 'xxxxxx.' + hostname, conf['keyx']
    assert_equal 'yyyyyy.zz', conf['keyy']
    assert_equal 'z3', conf['keyz']
    assert_equal 'd.zz.' + hostname, conf['alt_key']
  end

  def test_faild_plant
    d = create_driver
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.tag = 'test.xxxxxx';  d.run { d.emit({'f' => "message 1"}, time) }
    emits = d.emits
    assert_equal 1, emits.length

    d = create_driver %[
subtype forest_test
remove_prefix test
<template>
  key_name f
  suffix !
  tag __TAG__
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
    ]
    time = Time.parse("2012-01-02 13:14:15").to_i
    d.tag = 'test.raise.error';  d.run { d.emit({'f' => "message 1"}, time) }
    emits = d.emits
    assert_equal 0, emits.length
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
    assert_nil e[2]['not_started']

    e = emits[1]
    assert_equal 'out.second', e[0]
    assert_equal time, e[1]
    assert_equal "p4:message 2!", e[2]['f']
    assert_nil e[2]['not_started']

    e = emits[2]
    assert_equal 'out.foo.bar', e[0]
    assert_equal time, e[1]
    assert_equal "p1:message 3!", e[2]['f']
    assert_nil e[2]['not_started']

    e = emits[3]
    assert_equal 'out.foo.baz', e[0]
    assert_equal time, e[1]
    assert_equal "p2:message 4!", e[2]['f']
    assert_nil e[2]['not_started']

    e = emits[4]
    assert_equal 'out.bar', e[0]
    assert_equal time, e[1]
    assert_equal "p3:message 5!", e[2]['f']
    assert_nil e[2]['not_started']

    e = emits[5]
    assert_equal 'out.baz', e[0]
    assert_equal time, e[1]
    assert_equal "p4:message 6!", e[2]['f']
    assert_nil e[2]['not_started']

    e = emits[6]
    assert_equal 'out.foo.bar', e[0]
    assert_equal time, e[1]
    assert_equal "p1:message 7!", e[2]['f']
    assert_nil e[2]['not_started']

    e = emits[7]
    assert_equal 'out.bar', e[0]
    assert_equal time, e[1]
    assert_equal "p3:message 8!", e[2]['f']
    assert_nil e[2]['not_started']
  end
end
