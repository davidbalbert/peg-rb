module Peg
  class Node
    attr_reader :type, :children, :source_string

    def initialize(type, children, source_string)
      @type = type
      @children = children
      @source_string = source_string
    end
  end

  Success = Struct.new(:parse_tree, :nchars) do
    def success?
      true
    end

    def fail?
      false
    end
  end

  class Failure
    def success?
      false
    end

    def fail?
      true
    end
  end

  class Term
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      if input.start_with?(value)
        Success.new(value, value.size)
      else
        Failure.new
      end
    end

    def enumerable?
      false
    end
  end

  class Seq
    attr_reader :values

    def initialize(*values)
      @values = values
    end

    def parse(input)
      res = Success.new([], 0)

      values.each do |v|
        r = v.parse(input)

        return Failure.new unless r.success?

        res.value << r.value
        res.nchars += r.nchars
        input = input[r.nchars..]
      end

      res
    end

    def enumerable?
      false
    end
  end

  class Choice
    attr_reader :options

    def initialize(*options)
      @options = options
    end

    def parse(input)
      options.each do |opt|
        if (res = opt.parse(input)).success?
          return res
        end
      end

      Failure.new
    end

    def enumerable?
      false
    end
  end

  class CharSet
    attr_reader :chars

    def initialize(chars)
      @chars = chars
    end

    def parse(input)
      return Failure.new if input.empty?

      if chars.include?(input[0])
        Success.new(input[0], 1)
      else
        Failure.new
      end
    end

    def enumerable?
      false
    end
  end

  class ZeroOrMore
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = Success.new([], 0)

      loop do
        r = value.parse(input)

        return res unless r.success?

        res.value << r.value
        res.nchars += r.nchars
        input = input[r.nchars..]
      end
    end

    def enumerable?
      true
    end
  end

  class OneOrMore
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = Failure.new

      loop do
        r = value.parse(input)

        return res unless r.success?

        res = Success.new([], 0) if res.fail?
        res.value << r.value
        res.nchars += r.nchars
        input = input[r.nchars..]
      end
    end

    def enumerable?
      true
    end
  end

  class Maybe
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      if (res = value.parse(input)).success?
        res
      else
        Success.new(nil, 0)
      end
    end

    def enumerable?
      false
    end
  end

  class Any
    def parse(input)
      if input.size > 0
        Success.new(input[0], 1)
      else
        Failure.new
      end
    end

    def enumerable?
      false
    end
  end

  # Is this the right thing to do for empty
  # rules? I'm not sure.
  class Never
    def parse(input)
      Failure.new
    end

    def enumerable?
      false
    end
  end

  class And
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = value.parse(input)

      if res.success?
        Success.new(nil, 0)
      else
        Failure.new
      end
    end

    def enumerable?
      false
    end
  end

  class Not
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = value.parse(input)

      if res.success?
        Failure.new
      else
        Success.new(nil, 0)
      end
    end

    def enumerable?
      false
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
      debug(input) do
        body = grammar.send(rule)
        res = body.parse(input)

        if res.success? && grammar.actions&.respond_to?(rule)
          if body.enumerable?
            res.value = grammar.actions.send(rule, res.value)
          else
            res.value = grammar.actions.send(rule, *Array(res.value))
          end
        end

        res
      end
    end

    def enumerable?
      false
    end

    def debug(input)
      return yield unless Peg.debug

      puts " "*@@indent + "> Apply #{rule} -" + " "*(80-@@indent - rule.size) + input[0..input.index("\n")].inspect

      @@indent += 2
      res = yield
      @@indent -= 2

      res
    end
  end
end
