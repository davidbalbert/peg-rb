require 'peg/input_stream'

module Peg
  class MatchState
    attr_reader :grammar, :input, :start_expr, :bindings, :applications, :start_pos_stack, :memo

    def initialize(grammar, input, start_expr)
      @grammar = grammar
      @input = InputStream.new(input)
      @start_expr = start_expr
      @bindings = []
      @applications = []
      @start_pos_stack = []
      @memo = {}
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

    def start_pos
      start_pos_stack.last
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
      nbindings = bindings.size

      if syntactic? && expr.skip_space? && expr != Spaces
        eval(Spaces)
        pop
      end

      start_pos_stack.push(input.pos)
      res = expr.eval(self)

      if !res
        input.reset(start_pos)
        pop(bindings.size-nbindings)
      end

      start_pos_stack.pop

      if !res
        return res
      end

      if expr == start_expr && expr.skip_space? && expr != Spaces
        eval(Spaces)
        pop

        # TODO: we should really extend the last substring to cover up to input.pos
      end

      res
    end

    def current_substring
      input[start_pos...input.pos]
    end

    def push(*bs)
      bindings.push(*bs)
    end

    def pop(*args)
      bindings.pop(*args)
    end

    def pos
      input.pos
    end

    def memoized?(pos, rule)
      memo.key?([pos, rule])
    end

    def memoize_success(pos, rule, parse_tree)
      memo[[pos, rule]] = [parse_tree, input.pos]
    end

    def memoize_failure(pos, rule)
      memo[[pos, rule]] = [nil, pos]
    end

    def use_memoized(pos, rule)
      parse_tree, end_pos = memo[[pos, rule]]

      input.reset(end_pos)

      if parse_tree
        push(parse_tree)
        true
      else
        false
      end
    end
  end
end
