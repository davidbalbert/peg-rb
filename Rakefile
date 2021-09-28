require "rake/testtask"

task default: :test

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Generate the parser"
file "lib/peg/parser.rb" => ["lib/peg/meta_grammar.peg", "lib/peg/generator.rb"] do
  require "bundler/setup"

  $LOAD_PATH << File.expand_path("./lib", __dir__)
  require "peg"

  meta_grammar = File.read("lib/peg/meta_grammar.peg")
  source = Peg::Parser.parse(meta_grammar, actions: Peg::Generator.new("Peg::Parser")).value.to_rb

  File.write("lib/peg/parser.rb", source)
end
