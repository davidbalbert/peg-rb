module Peg
  class Grammar
    def self.match?(input, rule: :root)
      new.match?(input, rule: rule)
    end

    def self.parse(input, actions: nil, rule: :root)
      new(actions).parse(input, rule: rule)
    end


    attr_reader :actions

    def initialize(actions=nil)
      @actions = actions
    end

    def match?(input, rule: :root)
      parse(input, rule: rule).success?
    end

    def parse(input, rule: :root)
      Apply.new(self, rule).parse(input)
    end
  end
end
