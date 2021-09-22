class Peg
  def match?(input)
    !!parse(input)
  end

  def parse(input)
    root.parse(input)
  end

  Result = Struct.new(:value, :nchars)

  class Term
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      if input.start_with?(value)
        Result.new(value, value.size)
      else
        nil
      end
    end
  end

  class Seq
    attr_reader :values

    def initialize(*values)
      @values = values
    end

    def parse(input)
      res = Result.new([], 0)

      values.each do |v|
        r = v.parse(input)

        return nil unless r

        res.value << r.value
        res.nchars += r.nchars
        input = input[r.nchars..]
      end

      res
    end
  end

  class Choice
    attr_reader :options

    def initialize(*options)
      @options = options
    end

    def parse(input)
      options.each do |opt|
        if res = opt.parse(input)
          return res
        end
      end

      nil
    end
  end

  class CharSet
    attr_reader :chars

    def initialize(chars)
      @chars = chars
    end

    def parse(input)
      return nil if input.empty?

      if chars.include?(input[0])
        Result.new(input[0], 1)
      else
        nil
      end
    end
  end

  class ZeroOrMore
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = Result.new([], 0)

      loop do
        r = value.parse(input)

        return res unless r

        res.value << r.value
        res.nchars += r.nchars
        input = input[r.nchars..]
      end
    end
  end

  class OneOrMore
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = nil

      loop do
        r = value.parse(input)

        return res unless r

        res ||= Result.new([], 0)
        res.value << r.value
        res.nchars += r.nchars
        input = input[r.nchars..]
      end
    end
  end

  class Maybe
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      value.parse(input) || Result.new(nil, 0)
    end
  end

  class Any
    def parse(input)
      if input.size > 0
        Result.new(input[0], 1)
      else
        nil
      end
    end
  end

  class And
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = value.parse(input)
      res&.nchars = 0

      res
    end
  end

  class Not
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = value.parse(input)

      if res
        nil
      else
        Result.new(nil, 0)
      end
    end
  end

  class Apply
    @@indent = 0

    attr_reader :grammar, :rule

    def initialize(grammar, rule)
      @grammar = grammar
      @rule = rule
    end

    def parse(input)
      puts " "*@@indent + "> Apply #{rule} - #{input[0..input.index("\n")].inspect}"
      @@indent += 2
      res = grammar.send(rule).parse(input)
      @@indent -= 2

      res
    end
  end
end

