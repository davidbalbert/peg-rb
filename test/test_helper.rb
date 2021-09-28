# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "peg"

require "minitest/autorun"

class Test < MiniTest::Test
  def self.test(name, &block)
    define_method "test_#{name.gsub(/\s/, '_')}", &block
  end
end
