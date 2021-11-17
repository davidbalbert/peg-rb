require "rake/testtask"
require "bundler/gem_tasks"

task default: "lib/peg/parser.rb"

desc "Compile grammars"
task default: ["lib/peg/built_in_rules.rb", "lib/peg/parser.rb"]

desc "Compile lib/peg/parser.rb"
file "lib/peg/parser.rb" => ["lib/peg/parser.peg", "lib/peg/builder.rb", "bin/compile"] do
  xsystem("bin/compile lib/peg/parser.peg Peg::Parser -o lib/peg/parser.rb")
end

desc "Compile lib/peg/built_in_rules.rb"
file "lib/peg/built_in_rules.rb" => ["lib/peg/built_in_rules.peg", "lib/peg/parser.rb", "lib/peg/builder.rb", "bin/compile"] do
  xsystem("bin/compile lib/peg/built_in_rules.peg Peg::BuiltInRules -n Peg -o lib/peg/built_in_rules.rb")
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
