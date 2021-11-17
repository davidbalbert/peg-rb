module Peg
  class NonterminalNode
    attr_reader :name, :children, :source_string

    def initialize(name, children)
      @name = name
      @children = children
      @source_string = children.map(&:source_string).join
    end

    def terminal?
      false
    end

    def nonterminal?
      true
    end

    def iteration?
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

    def terminal?
      true
    end

    def nonterminal?
      false
    end

    def iteration?
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

    def iteration?
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

    def nchars
      0
    end
  end

  class Term
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      if input.start_with?(value)
        Success.new(TerminalNode.new(value), value.size)
      else
        Failure.new
      end
    end

    def arity
      1
    end
  end

  class Seq
    attr_reader :exprs

    def initialize(*exprs)
      @exprs = exprs
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      res = Success.new([], 0)

      exprs.each do |e|
        if skip_whitespace
          r = Apply.new(:spaces).parse(grammar, input, false, false)
          res.nchars += r.nchars
          input = input[r.nchars..]
        end

        r = e.parse(grammar, input, skip_whitespace, false)

        return Failure.new unless r.success?

        res.parse_tree.concat Array(r.parse_tree)
        res.nchars += r.nchars
        input = input[r.nchars..]
      end

      res
    end

    def arity
      exprs.map(&:arity).sum
    end
  end

  class Choice
    attr_reader :options

    def initialize(*options)
      @options = options
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      options.each do |opt|
        if (res = opt.parse(grammar, input, skip_whitespace, false)).success?
          return res
        end
      end

      Failure.new
    end

    def arity
      # TODO: ensure all options have the same arity
      options.size == 0 ? 0 : options.first.arity
    end
  end

  class CharSet
    attr_reader :chars

    def initialize(chars)
      @chars = chars
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      return Failure.new if input.empty?

      if chars.include?(input[0])
        Success.new(TerminalNode.new(input[0]), 1)
      else
        Failure.new
      end
    end

    def arity
      1
    end
  end

  class ZeroOrMore
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      nodes = expr.arity.times.map { IterationNode.new }
      res = Success.new(nodes, 0)

      loop do
        if skip_whitespace
          r = Apply.new(:spaces).parse(grammar, input, false, false)
          res.nchars += r.nchars
          input = input[r.nchars..]
        end

        r = expr.parse(grammar, input, skip_whitespace, false)

        return res unless r.success?

        results = Array(r.parse_tree)
        raise "results.size != nodes.size" unless results.size == res.parse_tree.size

        res.parse_tree.zip(results) do |iter, result|
          iter.children << result
        end

        res.parse_tree.each do |iter|
          iter.source_string << results.map(&:source_string).join
        end

        res.nchars += r.nchars
        input = input[r.nchars..]
      end
    end

    def arity
      expr.arity
    end
  end

  class OneOrMore
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      res = Failure.new

      nodes = expr.arity.times.map { IterationNode.new }

      loop do
        nskipped = 0

        if skip_whitespace
          r = Apply.new(:spaces).parse(grammar, input, false, false)
          skipped = r.nchars
          input = input[r.nchars..]
        end

        r = expr.parse(grammar, input, skip_whitespace, false)

        return res unless r.success?

        res = Success.new(nodes, 0) if res.fail?
        results = Array(r.parse_tree)
        raise "results.size != nodes.size" unless results.size == res.parse_tree.size

        res.parse_tree.zip(results) do |iteration, result|
          iteration.children << result
        end

        res.parse_tree.each do |iter|
          iter.source_string << results.map(&:source_string).join
        end

        res.nchars += r.nchars + nskipped
        input = input[r.nchars..]
      end
    end

    def arity
      expr.arity
    end
  end

  class Maybe
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      nodes = expr.arity.times.map { IterationNode.new }
      res = Success.new(nodes, 0)

      if skip_whitespace
        r = Apply.new(:spaces).parse(grammar, input, false, false)
        res.nchars += r.nchars
        input = input[r.nchars..]
      end

      if (r = expr.parse(grammar, input, skip_whitespace, false)).success?
        results = Array(r.parse_tree)
        raise "results.size != nodes.size" unless results.size == res.parse_tree.size

        res.parse_tree.zip(results) do |iteration, result|
          iteration.children << result
        end

        res.parse_tree.each do |iter|
          iter.source_string << results.map(&:source_string).join
        end

        res.nchars += r.nchars
      end

      res
    end

    def arity
      expr.arity
    end
  end

  class Any
    def parse(grammar, input, skip_whitespace, start_rule)
      if input.size > 0
        Success.new(TerminalNode.new(input[0]), 1)
      else
        Failure.new
      end
    end

    def arity
      1
    end
  end

  # Is this the right thing to do for empty
  # rules? I'm not sure.
  class Never
    def parse(grammar, input, skip_whitespace, start_rule)
      Failure.new
    end

    def arity
      0
    end
  end

  class And
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      res = expr.parse(grammar, input, skip_whitespace, false)

      if res.success?
        Success.new(nil, 0)
      else
        Failure.new
      end
    end

    def arity
      expr.arity
    end
  end

  class Not
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      res = expr.parse(grammar, input, skip_whitespace, false)

      if res.success?
        Failure.new
      else
        Success.new(nil, 0)
      end
    end

    def arity
      0
    end
  end

  class Super
    attr_reader :rule

    def initialize(rule)
      @rule = rule
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      # use ancestors to make this work with mixins, just like
      # the super keyword.
      #
      # This might need to be changed to handle a weird case if
      # someone prepends a mixin to grammar.
      superclass = grammar.class.ancestors[1]

      m = superclass.instance_method(rule)
      body = m.bind(grammar).call

      res = body.parse(grammar, input, skip_whitespace, false)

      return res
    end
  end

  class Apply
    @@indent = 0

    attr_reader :rule

    def initialize(rule)
      @rule = rule
    end

    def parse(grammar, input, skip_whitespace, start_rule)
      skip_whitespace = rule.to_s[0].match?(/\A[[:upper:]]\z/)

      if skip_whitespace
        res = Apply.new(:spaces).parse(grammar, input, false, false)
        input = input[res.nchars..]
      end

      body = grammar.send(rule)
      res = body.parse(grammar, input, skip_whitespace, false)

      return res if res.fail?

      if skip_whitespace && start_rule
        r = Apply.new(:spaces).parse(grammar, input, false, false)
        res.nchars += r.nchars
        input = input[r.nchars..]
      end

      Success.new(NonterminalNode.new(rule, Array(res.parse_tree)), res.nchars)
    end

    def arity
      1
    end
  end
end
