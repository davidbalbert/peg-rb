require 'peg/refinements'

module Peg
  module SignatureExtraction
    refine Proc do
      def signature
        MethodSignature.new(&self)
      end
    end
  end

  class MethodSignature
    using ToLambda

    class NoopProxy < BasicObject
      def method_missing(name, *args, **kwargs, &block)
        # noop
      end
    end

    class DefaultArgumentExtractor
      def self.extract(&block)
        new(&block).extract
      end

      attr_reader :block

      def initialize(&block)
        @block = block
      end

      def extract
        optional = block.parameters.select { |(type, _)| type == :opt || type == :key }.map { |(_, name)| name }

        bindings.select { |name, val| optional.include? name }
      end

      def bindings
        bs = nil

        trace = TracePoint.new(:b_call) do |tp|
          bs = tp.parameters.map { |_, name| [name, tp.binding.eval(name.to_s)]}.to_h
        end

        proxy = NoopProxy.new

        trace.enable
        proxy.instance_exec(*args, **kwargs, &block)
        trace.disable

        bs
      end

      def args
        nreq = block.parameters.count { |(type, _)| type == :req }

        nreq.times.map { nil }
      end

      def kwargs
        names = block.parameters.select { |(type, _)| type == :keyreq }.map { |_, name| name }

        names.map { |n| [n, nil] }.to_h
      end
    end

    class Parameter
      attr_reader :name, :type, :default

      ATOMS = [String, Symbol, Integer, Float, Complex, TrueClass, FalseClass, NilClass, Regexp, Module]

      def initialize(type, name, default=nil)
        @type, @name, @default = type, name.to_s, default
      end

      def to_s
        case type
        when :req
          name
        when :opt
          name + "=" + default_string
        when :rest
          "*" + name
        when :keyreq
          name + ":"
        when :key
          name + ": " + default_string
        when :keyrest
          "**" + name
        when :block
          "&" + name
        else
          raise ArgumentError, "Unknown type"
        end
      end

      def default_string
        check_roundtrip!

        default.inspect
      end

      def check_roundtrip!(o=default)
        case o
        when *ATOMS
          return
        when Array
          o.each { |e| check_roundtrip!(e) }
        when Hash
          o.each do |k, v|
            check_roundtrip!(k)
            check_roundtrip!(v)
          end
        when Range
          check_roundtrip!(o.begin)
          check_roundtrip!(o.end)
        else
          raise ArgumentError, "#{o.inspect} cannot be serialized into a string"
        end
      end
    end


    attr_reader :block

    def initialize(&block)
      @block = block
    end

    def to_s
      parameters.map(&:to_s).join(", ")
    end

    def parameters
      @parameters ||= block.to_lambda.parameters.map do |type, name|
        Parameter.new(type, name, default_values[name])
      end
    end

    def default_values
      @default_values ||= DefaultArgumentExtractor.extract(&block)
    end
  end
end
