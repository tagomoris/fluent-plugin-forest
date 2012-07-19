# fluent-plugin-forest

## Component

### ForestOutput

ForestOutput creates sub plugin instance of a output plugin dynamically per tag, from template configurations.
In template configurations, you can write configuration lines for overall tags by <template>, and for specified tags by <case TAG_PATTERN>, and you can use \_\_TAG\_\_ placeholder at anywhere in <template> and <case>.

This plugin helps you if you are writing very long configurations by copy&paste with a little little diff for many tags.

Other supported placeholders:
* \_\_HOSTNAME\_\_
  * replaced with string specified by 'hostname' configuration value, or (default) result of 'hostname' command

You SHOULD NOT use ForestOutput for tags increasing infinitly. 

## Configuration

### ForestOutput

If you are writing long long configurations like below:

    <match service.blog>
      type file
      time_slice_format %Y%m%d%H
      compress yes
      path /var/log/blog.*.log
    </match>
    <match service.portal>
      type file
      time_slice_format %Y%m%d%H
      compress yes
      path /var/log/portal.*.log
    </match>
    <match service.news>
      type file
      time_slice_format %Y%m%d%H
      compress yes
      path /var/log/news.*.log
    </match>
    <match service.sns>
      type file
      time_slice_format %Y%m%d%H
      compress yes
      path /var/log/sns.*.log
    </match>
    # ...

You can write configuration with ForestOutput like below:

    <match service.*>
      type forest
      subtype file
      remove_prefix service
      <template>
        time_slice_format %Y%m%d%H
        compress yes
        path /var/log/__TAG__.*.log
      </template>
    </match>

If you want to place logs /var/archive for `service.search.**` as filename with hostname, without compression, `case` directive is useful:

    <match service.*>
      type forest
      subtype file
      remove_prefix service
      <template>
        time_slice_format %Y%m%d%H
      </template>
      <case search.**>
        compress no
        path /var/archive/__TAG__.__HOSTNAME__.*.log
      </case>
      <case *>
        compress yes
        path /var/log/__TAG__.*.log
      </case>
    </match>

`case` configuration overwrites `template` configuration, so you can also write like this:

    <match service.*>
      type forest
      subtype file
      remove_prefix service
      <template>
        time_slice_format %Y%m%d%H
        compress yes
        path /var/log/__TAG__.*.log
      </template>
      <case search.**>
        compress no
        path /var/archive/__TAG__.*.log
      </case>
    </match>

## TODO

* consider what to do next
* patches welcome!

## Copyright

* Copyright (c) 2012- TAGOMORI Satoshi (tagomoris)
* License
  * Apache License, Version 2.0
