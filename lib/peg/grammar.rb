module Peg
  class Grammar
    def self.match?(input, rule: :root)
      new.match?(input, rule: rule)
    end

    def self.parse(input, rule: :root)
      new.parse(input, rule: rule)
    end
    
    def self.create_semantics
      Semantics.new(self)
    end

    def match?(input, rule: :root)
      parse(input, rule: rule).success?
    end

    def parse(input, rule: :root)
      Apply.new(self, rule).parse(input)
    end
  end
end
