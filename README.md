# fluent-plugin-forest

## Component

### ForestOutput

ForestOutput creates sub plugin instance of a output plugin dynamically per tag, from template configurations.
In template configurations, you can write configuration lines for overall tags by <template>, and for specified tags by <case TAG_PATTERN>, and you can use \_\_TAG\_\_ (or ${tag}) placeholder at anywhere in <template> and <case>.

This plugin helps you if you are writing very long configurations by copy&paste with a little little diff for many tags.

Other supported placeholders:
* \_\_HOSTNAME\_\_ (or ${hostname})
  * replaced with string specified by 'hostname' configuration value, or (default) result of 'hostname' command

You SHOULD NOT use ForestOutput for tags increasing infinitly. 

## Configuration

**NOTICE:** If you configure `fluent-plugin-forest` with `buffer_type file` (or plugins, default buffer type is file), you should modify `buffer_path` with `__TAG__` (or `${tag}`) to help to use buffer files for each tags.

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
        path /var/log/${tag}.*.log
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

Current version of this plugin doesn't support subsections in `<template>` and `<case>`. This doesn't works as we expect.

    <match service.*>
      type forest
      subtype copy
      <template>
        <store>
          type file
          path /path/to/copy1
        </store>
        <store>
          type file
          path /path/to/copy2
        </store>
      </template>
      <case search.**>
        <store>
          type file
          path /path/to/copy3
        </store>
      </case>
    </match>

For copy+forest pattern, you can use `fluent-plugin-forest` in `<store>` section of out\_copy. (except for variable numbers of `<store>` sections.)

## TODO

* Subsections support in `<template>` and `<case>`
* patches welcome!

## Copyright

* Copyright (c) 2012- TAGOMORI Satoshi (tagomoris)
* License
  * Apache License, Version 2.0
