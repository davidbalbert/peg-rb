require 'delegate'

require 'peg/method_signature'

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

            op = _algebra.#{accessor}.new(self)

            if op.respond_to?(name)
              action = op.method(name)
            elsif !iteration? && children.size == 1
              action = ->(child) { child.#{name}(#{signature.to_s}) }
            elsif nonterminal? && op.respond_to?(:_nonterminal)
              action = op.method(:_nonterminal)
            else
              raise NoMethodError, "missing semantics for " + name + " for #{name}"
            end

            if iteration?
              action.call(children)
            else
              action.call(*children)
            end
          end
        RUBY
      end

      attr_reader :_algebra

      def initialize(o, algebra)
        super(o)
        @_algebra = algebra
      end

      def children
        super.map do |child|
          self.class.new(child, _algebra)
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
        const_set :Wrapper, Class.new(wrapper)
      end
    end

    def self.[](grammar)
      supergrammar = const_defined?(:Grammar) ? const_get(:Grammar) : Grammar

      unless grammar < supergrammar
        raise ArgumentError, "#{grammar} must be a subclass of #{supergrammar}."
      end

      Class.new(self) do
        const_set(:Grammar, grammar)
      end
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
