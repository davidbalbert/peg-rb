require 'peg/refinements'
require 'peg/semantics'
require 'peg/runtime'

module Peg
  class Grammar
    using ModuleAttribute

    module_attribute :default_rule

    def self.rules
      @rules ||= []
    end

    def self.match?(input, rule: nil)
      new.match?(input, rule: rule || default_rule)
    end

    def self.parse(input, rule: nil)
      new.parse(input, rule: rule || default_rule)
    end

    def match?(input, rule:)
      parse(input, rule: rule).success?
    end

    def parse(input, rule:)
      Apply.new(rule).parse(self, input)
    end
  end
end
