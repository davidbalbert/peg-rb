module Peg
  class Grammar
    attr_reader :actions

    def self.match?(input)
      new.match?(input)
    end

    def self.parse(input, actions: nil, rule: :root)
      new(actions).parse(input, rule: rule)
    end

    def initialize(actions=nil)
      @actions = actions
    end

    def match?(input)
      parse(input).success?
    end

    def parse(input, rule:)
      Apply.new(self, rule).parse(input)
    end
  end
end
