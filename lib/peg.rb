module Peg
  module ModuleAttribute
  refine Module do
    def module_attribute(name, default: nil)
      define_singleton_method name do
        instance_variable_get "@#{name}"
      end

      define_singleton_method "#{name}=" do |new_value|
        instance_variable_set "@#{name}", new_value
      end

      if default != nil
        instance_variable_set "@#{name}", default
      end
    end
  end
  end

  using ModuleAttribute

  module_attribute :debug, default: false
end

require 'peg/runtime'
require 'peg/grammar'
require 'peg/parser'
require 'peg/generator'
