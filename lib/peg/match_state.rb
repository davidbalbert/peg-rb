module Peg
  class MatchState
    attr_reader :grammar, :input, :start_expr, :bindings, :applications

    def initialize(grammar, input, start_expr)
      @grammar = grammar
      @input = InputStream.new(input)
      @start_expr = start_expr
      @bindings = []
      @applications = []
    end

    def result
      if eval(start_expr)
        Success.new(bindings.first)
      else
        Failure.new
      end
    end

    def applying(application)
      applications.push(application)

      yield
    ensure
      applications.pop
    end

    def current_application
      applications.last
    end

    def current_body
      grammar.send(current_application.rule)
    end

    def super_body
      # Use ancestors to make this work with mixins, just like
      # the super keyword.
      #
      # This might need to be changed to handle a weird case if
      # someone prepends a mixin to grammar.
      superclass = grammar.class.ancestors[1]
      m = superclass.instance_method(current_application.rule)
      m.bind(grammar).call
    end

    def syntactic?
      if current_application
        current_application.syntactic?
      else
        start_expr.syntactic?
      end
    end

    Spaces = Apply.new(:spaces)

    def eval(expr)
      pos = input.pos
      nbindings = bindings.size

      if syntactic? && expr.skip_space? && expr != Spaces
        eval(Spaces)
        pop
      end

      res = expr.eval(self)

      if !res
        input.reset(pos)
        pop(bindings.size-nbindings)
      end

      if expr == start_expr && expr.skip_space? && expr != Spaces
        eval(Spaces)
        pop
      end

      res
    end

    def push(*bs)
      bindings.push(*bs)
    end

    def pop(*args)
      bindings.pop(*args)
    end
  end
end
