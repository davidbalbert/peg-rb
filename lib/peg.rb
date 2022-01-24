require 'peg/refinements'
require 'peg/builder'

module Peg
  using ModuleAttribute

  module_attribute :debug, default: false

  def self.compile(source, namespace: Object)
    Peg::Builder.new(source, namespace: namespace).build
  end

  def self.compile_to_rb(source, class_name: nil, namespace: Object)
    Peg::Builder.new(source, namespace: namespace).to_rb(class_name)
  end
end
