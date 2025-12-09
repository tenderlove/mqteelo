require_relative "tool/gen"

file 'lib/mqteelo_gen.rb' => ["Rakefile", "tool/gen.rb"] do
  doc = DOC
  types = packet_types doc
  props = properties doc
  rs = reasons(doc)
  properties_by_type = Hash.new { |h,k| h[k] = [] }
  props.each { |p| p.packets.each { |type| properties_by_type[type] << p } }

  File.open('lib/mqteelo_gen.rb', 'w') { |f|
    f.puts "class MQTeelo::Server"
    f.puts ReasonTemplate.result(rs)
    f.puts
    f.puts "  private"
    f.puts
    f.puts Dispatch.result(types)
    f.puts
    f.puts PropertyTemplate.result(properties_by_type)
    f.puts "end"
  }
end

task default: 'lib/mqteelo_gen.rb'
