require 'delegate'

require 'peg/method_signature'
require 'peg/grammar'

# Each Semantics has a Wrapper. This wraps parse tree nodes with the
# methods for each of the Semantics' operations (e.g. eval, pretty_print,
# etc.), and delegates everything else to the Node. Each Semantics has
# multiple Operations. Each Operation wraps a Wrapper (so, two levels of
# delegation). Operations contain methods for each Node type in the Semantics'
# Grammar (e.g. MultExp, Number, etc.). This means that the Operation for `eval`
# (OpEval) responds to all the methods for each Node in eval, all the methods
# for each of the operations (e.g. eval, pretty_print), *and* all the methods
# on the Node itself.
#
# If Semantics S2 subclasses S1, then S2::Wrapper subclasses S1::Wrapper. Similarly,
# if you define an operation `eval` on S1 (S1::OpEval), and then define it again
# on S2, S2::OpEval subclasses S1::OpEval. This allows you to use the super keyword
# in your semantic actions.

module Peg
  class Semantics
    using SignatureExtraction
    using Classify

    class Wrapper < SimpleDelegator
      def self.add_operation(name, accessor, signature)
        params = signature.parameters.map(&:name)

        class_eval do
          attr_reader *params
        end

        class_eval <<~RUBY
          def #{name}(#{signature.to_s})
            #{params.map { |n| "@#{n} = #{n}" }.join("\n") }

            op = _semantics.#{accessor}.new(self)

            if op.respond_to?(name)
              action = op.method(name)
            elsif nonterminal? && op.respond_to?(:_nonterminal)
              action = op.method(:_nonterminal)
            elsif !iteration? && children.size == 1
              action = ->(child) { child.#{name}(#{signature.to_s}) }
            else
              raise NoMethodError, "missing semantics for " + name.to_s + " for #{name}"
            end

            if iteration?
              action.call(children)
            else
              action.call(*children)
            end
          end
        RUBY
      end

      attr_reader :_semantics

      def initialize(o, semantics)
        super(o)
        @_semantics = semantics
      end

      def children
        super.map do |child|
          self.class.new(child, _semantics)
        end
      end
    end

    class Operation < SimpleDelegator
    end

    def self.wrapper
      const_get(:Wrapper)
    end

    def self.inherited(subclass)
      subclass.class_eval do
        if !Thread.current[:_peg_subclassing_semantics_with_grammar] && !const_defined?(:Grammar)
          raise TypeError, "You cannot subclass Peg::Semantics direclty (e.g. class S < Peg::Semantics). You need to specify a Grammar (e.g. class S < Peg::Semantics[G])."
        end

        const_set :Wrapper, Class.new(wrapper)
      end
    end

    def self.[](grammar)
      supergrammar = const_defined?(:Grammar) ? const_get(:Grammar) : Grammar

      unless grammar < supergrammar
        raise TypeError, "#{grammar} must be a subclass of #{supergrammar}."
      end

      Thread.current[:_peg_subclassing_semantics_with_grammar] = true

      subclass = Class.new(self) do
        const_set(:Grammar, grammar)
      end

      Thread.current[:_peg_subclassing_semantics_with_grammar] = nil

      subclass
    end

    def self.def_operation(name, &block)
      const_name  = :"Op#{name.to_s.classify}"
      accessor = :"_op_#{name}"

      superclass = const_defined?(const_name) ? const_get(const_name) : Operation
      op = Class.new(superclass, &block)

      const_set const_name, op

      define_method accessor do
        op
      end

      wrapper.add_operation(name, accessor, block.signature)

      name.intern
    end

    def self.wrap(result)
      wrapper.new(result.parse_tree, new)
    end
  end
end
