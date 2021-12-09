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

    def initialize(children, source_string)
      @children = children
      @source_string = source_string
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

  class InputStream
    attr_reader :pos

    def initialize(s)
      @s = s
      @pos = 0
    end

    def mark
      @pos
    end

    def reset(pos)
      @pos = pos
    end

    def getc
      c = @s[@pos]
      @pos += 1 unless c.nil?

      c
    end

    def empty?
      @pos == @s.size
    end

    def size
      @s.size - @pos
    end

    def start_with?(value)
      value.chars.each do |c|
        if c != getc
          return false
        end
      end

      true
    end
  end

  Success = Struct.new(:parse_tree) do
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

    def parse(state)
      if state.input.start_with?(value)
        state.push(TerminalNode.new(value))
        true
      else
        false
      end
    end

    def arity
      1
    end

    def skip_space?
      true
    end
  end

  class Seq
    attr_reader :exprs

    def initialize(*exprs)
      @exprs = exprs
    end

    def parse(state)
      exprs.each do |e|
        unless state.eval(e)
          return false
        end
      end

      true
    end

    def arity
      exprs.map(&:arity).sum
    end

    def skip_space?
      false
    end
  end

  class Choice
    attr_reader :options

    def initialize(*options)
      @options = options
    end

    def parse(state)
      options.each do |opt|
        if state.eval(opt)
          return true
        end
      end

      false
    end

    def arity
      # TODO: ensure all options have the same arity
      options.size == 0 ? 0 : options.first.arity
    end

    def skip_space?
      false
    end
  end

  class CharSet
    attr_reader :chars

    def initialize(chars)
      @chars = chars
    end

    def parse(state)
      return false if state.input.empty?

      c = state.input.getc

      if chars.include?(c)
        state.push(TerminalNode.new(c))
        true
      else
        false
      end
    end

    def arity
      1
    end

    def skip_space?
      true
    end
  end

  class Iter
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def parse(state)
      matches = 0
      cols = arity.times.map { [] }
      source_string = ""

      while matches < range.end && state.eval(expr)
        bindings = state.pop(arity)

        cols.zip(bindings).each do |col, b|
          col << b
        end

        source_string << bindings.map(&:source_string).join

        matches += 1
        last_pos = state.input.pos
      end

      if matches < range.begin
        return false
      end

      cols.each do |col|
        state.push(IterationNode.new(col, source_string))
      end

      true
    end

    def arity
      expr.arity
    end

    def skip_space?
      false
    end
  end

  class ZeroOrMore < Iter
    def range
      0..Float::INFINITY
    end
  end

  class OneOrMore < Iter
    def range
      1..Float::INFINITY
    end
  end

  class Maybe < Iter
    def range
      0..1
    end
  end

  class Any
    def parse(state)
      if state.input.size > 0
        state.push(TerminalNode.new(state.input.getc))
        true
      else
        false
      end
    end

    def arity
      1
    end

    def skip_space?
      true
    end
  end

  # Is this the right thing to do for empty
  # rules? I'm not sure.
  class Never
    def parse(state)
      false
    end

    def arity
      0
    end

    def skip_space?
      false
    end
  end

  class And
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def parse(state)
      pos = state.input.pos
      res = state.eval(expr)
      state.input.reset(pos)

      res
    end

    def arity
      expr.arity
    end

    def skip_space?
      false
    end
  end

  class Not
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    def parse(state)
      pos = state.input.pos
      res = state.eval(expr)
      state.input.reset(pos)

      !res
    end

    def arity
      0
    end

    def skip_space?
      false
    end
  end

  class Super
    attr_reader :rule

    def initialize(rule)
      @rule = rule
    end

    def parse(state)
      body = state.super_body

      state.eval(body)
    end

    def arity
      1
    end

    def skip_space?
      true
    end
  end

  class Apply
    attr_reader :rule

    def initialize(rule)
      @rule = rule
    end

    def parse(state)
      state.applying(self) do
        body = state.current_body

        if state.eval(body)
          bindings = state.pop(body.arity)
          state.push(NonterminalNode.new(rule, bindings))

          true
        else
          false
        end
      end
    end

    def syntactic?
      rule.to_s[0] == rule.to_s[0].upcase
    end

    def arity
      1
    end

    def skip_space?
      true
    end
  end
end
