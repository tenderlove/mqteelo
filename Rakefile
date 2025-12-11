require "rake/testtask"
require_relative "tool/gen"

file 'lib/mqteelo_gen.rb' => ["Rakefile", "tool/gen.rb"] do
  doc = DOC
  types = packet_types doc
  props = properties doc
  rs = reasons(doc)
  properties_by_type = Hash.new { |h,k| h[k] = [] }
  props.each { |p| p.packets.each { |type| properties_by_type[type] << p } }

  File.open('lib/mqteelo_gen.rb', 'w') { |f|
    f.puts "module MQTeelo"
    f.puts "  module Properties"
    f.puts PropertyConstants.result(props, indent: 4)
    f.puts "  end"
    f.puts
    f.puts "  module Reasons"
    f.puts ReasonTemplate.result(rs, indent: 4)
    f.puts "  end"
    f.puts
    f.puts "  class Connection"
    f.puts
    f.puts "    private"
    f.puts
    f.puts Dispatch.result(types, indent: 4)
    f.puts
    f.puts PropertyTemplate.result(properties_by_type, indent: 4)
    f.puts "  end"
    f.puts "end"
  }
end

task default: 'lib/mqteelo_gen.rb'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = true
end
