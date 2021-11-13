module Peg
  class NonterminalNode
    attr_reader :name, :children, :source_string

    def initialize(name, children)
      @name = name
      @children = children
      @source_string = children.map(&:source_string).join
    end

    def arity
      children.size
    end

    def terminal?
      false
    end

    def nonterminal?
      true
    end

    def enumerable?
      false
    end

    def pretty_print(pp)
      pp.text "(#{name}"

      pp.nest(2) do
        children.each do |c|
          pp.breakable
          pp.pp(c)
        end
      end
      pp.text ")"
    end
  end

  class TerminalNode
    attr_reader :value
    alias source_string value

    def initialize(value)
      @value = value
    end

    def name
      "_terminal"
    end

    def children
      []
    end

    def arity
      1
    end

    def terminal?
      true
    end

    def nonterminal?
      false
    end

    def enumerable?
      false
    end

    def pretty_print(pp)
      pp.text "(_terminal "
      pp.pp(value)
      pp.text ")"
    end
  end

  class IterationNode
    attr_reader :children, :source_string

    def initialize
      @children = []
      @source_string = ""
    end

    def arity
      children.size
    end

    def name
      "_iter"
    end

    def terminal?
      false
    end

    def nonterminal?
      false
    end

    def enumerable?
      true
    end

    def pretty_print(pp)
      pp.text "(#{name}"

      pp.nest(2) do
        children.each do |c|
          pp.breakable
          pp.pp(c)
        end
      end
      pp.text ")"
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

    def parse(grammar, input)
      if input.start_with?(value)
        Success.new(TerminalNode.new(value), value.size)
      else
        Failure.new
      end
    end
  end

  class Seq
    attr_reader :values

    def initialize(*values)
      @values = values
    end

    def parse(grammar, input)
      res = Success.new([], 0)

      values.each do |v|
        r = v.parse(grammar, input)

        return Failure.new unless r.success?

        res.parse_tree.concat Array(r.parse_tree)
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

    def parse(grammar, input)
      options.each do |opt|
        if (res = opt.parse(grammar, input)).success?
          return res
        end
      end

      Failure.new
    end
  end

  class CharSet
    attr_reader :chars

    def initialize(chars)
      @chars = chars
    end

    def parse(grammar, input)
      return Failure.new if input.empty?

      if chars.include?(input[0])
        Success.new(TerminalNode.new(input[0]), 1)
      else
        Failure.new
      end
    end
  end

  class ZeroOrMore
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(grammar, input)
      res = Success.new(IterationNode.new, 0)

      loop do
        r = value.parse(grammar, input)

        return res unless r.success?

        res.parse_tree.children.concat Array(r.parse_tree)
        res.parse_tree.source_string << Array(r.parse_tree).map(&:source_string).join
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

    def parse(grammar, input)
      res = Failure.new

      loop do
        r = value.parse(grammar, input)

        return res unless r.success?

        res = Success.new(IterationNode.new, 0) if res.fail?
        res.parse_tree.children.concat Array(r.parse_tree)
        res.parse_tree.source_string << Array(r.parse_tree).map(&:source_string).join
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

    def parse(grammar, input)
      res = Success.new(IterationNode.new, 0)

      if (r = value.parse(grammar, input)).success?
        res.parse_tree.children.concat Array(r.parse_tree)
        res.parse_tree.source_string << Array(r.parse_tree).map(&:source_string).join
        res.nchars += r.nchars
      end

      res
    end
  end

  class Any
    def parse(grammar, input)
      if input.size > 0
        Success.new(TerminalNode.new(input[0]), 1)
      else
        Failure.new
      end
    end
  end

  # Is this the right thing to do for empty
  # rules? I'm not sure.
  class Never
    def parse(grammar, input)
      Failure.new
    end
  end

  class And
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(grammar, input)
      res = value.parse(grammar, input)

      if res.success?
        Success.new(nil, 0)
      else
        Failure.new
      end
    end
  end

  class Not
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(grammar, input)
      res = value.parse(grammar, input)

      if res.success?
        Failure.new
      else
        Success.new(nil, 0)
      end
    end
  end

  class Apply
    @@indent = 0

    attr_reader :rule

    def initialize(rule)
      @rule = rule
    end

    def parse(grammar, input)
      debug(input) do
        body = grammar.send(rule)
        res = body.parse(grammar, input)

        return res if res.fail?

        Success.new(NonterminalNode.new(rule, Array(res.parse_tree)), res.nchars)
      end
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
