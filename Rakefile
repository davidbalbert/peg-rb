require "rake/testtask"

task default: "lib/peg/parser.rb"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Compile lib/peg/parser.rb from lib/peg/meta_grammar.peg"
file "lib/peg/parser.rb" => ["lib/peg/meta_grammar.peg", "lib/peg/generator.rb"] do
  xsystem("exe/peg lib/peg/meta_grammar.peg Peg::Parser -o lib/peg/parser.rb")
end

def xsystem(cmd)
  puts cmd
  system cmd
end
