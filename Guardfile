# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'test' do
  # lib
  watch(%r{^lib/fluent/plugin/.+\.rb$})
  # test
  watch('test/helper.rb')
  watch(%r{^test/output/.+\.rb$})
  watch(%r{^test/plugin/.+\.rb$})
end

