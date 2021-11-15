module Peg
  module Indentation
    refine String do
      def indent(n)
        split("\n").map { |l| " "*n + l }.join("\n")
      end
    end
  end

  module ModuleAttribute
    refine Module do
      def module_attribute(name, default: nil)
        define_singleton_method name do
          instance_variable_get "@#{name}"
        end

        define_singleton_method "#{name}=" do |new_value|
          instance_variable_set "@#{name}", new_value
        end

        if default != nil
          instance_variable_set "@#{name}", default
        end
      end
    end
  end

  module Classify
    refine String do
      def classify
        split(/_+/).map { |part| part.capitalize }.join
      end
    end
  end

  module ToLambda
    refine Proc do
      def to_lambda
        return self if lambda?

        o = Object.new
        o.define_singleton_method :_, &self
        o.method(:_).to_proc
      end
    end
  end
end
