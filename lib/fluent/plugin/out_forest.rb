class Fluent::ForestOutput < Fluent::Output
  Fluent::Plugin.register_output('forest', self)



# <match converted.*>
#   type output_forest
#   subtype hoop
#   remove_prefix converted
#   <template>
#     username hoopuser
#     flush_interval 60s
#     output_include_time false
#     output_include_tag  false
#     output_data_type attr:field1,field2,field3,field4
#     add_newline true
#   </template>
#   <parameter>
#     path /hoop/log/%Y%m%d/%TAG-%Y%m%d-%H.log
#   </parameter>
#   <tag blog>
#     hoop_server hoop1.local:14000
#   </tag>
#   <tag news>
#     hoop_server hoop2.local:14000
#   </tag>
#   <tag *>
#     hoop_server hoop3.local:14000
#   </tag>
# </match>

  
end
