require 'peg/refinements'
require 'peg/builder'

module Peg
  using ModuleAttribute

  module_attribute :debug, default: false

  def self.build(source)
    Peg::Builder.new(source).build
  end
end
