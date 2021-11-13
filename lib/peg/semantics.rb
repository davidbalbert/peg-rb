require 'delegate'

# semantics = Peg::Parser.create_semantics.def_operation :to_rb do |pretty_print|
#   def Grammar(foo, bar, baz)
#   end
#
#   def Rule(name, _, body)
#   end
# end
#
# result = grammar.parse("hello world")
# semantics.wrap(result).to_rb

module Peg
  class Semantics
    class Wrapper < SimpleDelegator
      attr_reader :_semantics

      def initialize(node, semantics)
        super(node)
        @_semantics = semantics
      end

      def children
        super.map do |child|
          self.class.new(child, _semantics)
        end
      end
    end

    attr_reader :grammar, :operations, :wrapper

    def initialize(grammar)
      @grammar = grammar
      @operations = {}
      @wrapper = Class.new(Wrapper)
    end

    def def_operation(name, &block)
      name = name.intern

      if operations.key?(name)
        raise ArgumentError, "an operation called `#{name}' has already been defined"
      end

      operations[name] = Module.new(&block)
      args = block.parameters.map { |(_, name)| name }

      wrapper.class_eval do
        attr_reader *args
      end

      wrapper.class_eval <<~RUBY
      def #{name}(#{args.join(', ')})
        puts "== " + name.to_s

        #{args.empty? ? "" : args.map { "@#{_1}" }.join(', ') + " = " + args.join(', ')}

        if _semantics.operations[:#{name}].method_defined?(name)
          action = _semantics.operations[:#{name}].instance_method(name).bind(self)
        end

        if _semantics.operations[:#{name}].method_defined?("_nonterminal")
          nonterminal_action = _semantics.operations[:#{name}].instance_method("_nonterminal").bind(self)
        end

        if !action && nonterminal? && arity == 1
          action = ->(child) { child.#{name}(#{args.join(", ")}) }
        elsif !action && nonterminal? && nonterminal_action
          action = nonterminal_action
        elsif !action
          raise "#{name}: missing semantics for " + name # todo, figure out what type of error this should be
        end

        if enumerable?
          action.call(children)
        else
          action.call(*children)
        end
      end
      RUBY

      self
    end

    def wrap(result)
      wrapper.new(result.parse_tree, self)
    end
  end
end
