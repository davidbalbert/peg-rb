require "rake/testtask"

task default: "lib/peg/parser.rb"

desc "Compile lib/peg/parser.rb from lib/peg/meta_grammar.peg"
file "lib/peg/parser.rb" => ["lib/peg/meta_grammar.peg", "lib/peg/builder.rb", "bin/compile"] do
  xsystem("bin/compile lib/peg/meta_grammar.peg Peg::Parser -o lib/peg/parser.rb")
end

def xsystem(cmd)
  puts cmd
  system cmd
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end
