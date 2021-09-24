class Module
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

class Peg
  module_attribute :debug, default: false

  attr_reader :actions

  def self.match?(input)
    new.match?(input)
  end

  def self.parse(input, actions: nil)
    new(actions).parse(input)
  end

  def initialize(actions=nil)
    @actions = actions
  end

  def match?(input)
    parse(input).success?
  end

  def parse(input)
    root.parse(input)
  end

  Success = Struct.new(:value, :nchars) do
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

    def parse(input)
      if input.start_with?(value)
        Success.new(value, value.size)
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

    def parse(input)
      res = Success.new([], 0)

      values.each do |v|
        r = v.parse(input)

        return Failure.new unless r.success?

        res.value << r.value
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

    def parse(input)
      options.each do |opt|
        if (res = opt.parse(input)).success?
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

    def parse(input)
      return Failure.new if input.empty?

      if chars.include?(input[0])
        Success.new(input[0], 1)
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

    def parse(input)
      res = Success.new([[]], 0)

      loop do
        r = value.parse(input)

        return res unless r.success?

        res.value[0] << r.value
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

    def parse(input)
      res = Failure.new

      loop do
        r = value.parse(input)

        return res unless r.success?

        res = Success.new([[]], 0) if res.fail?
        res.value[0] << r.value
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

    def parse(input)
      if (res = value.parse(input)).success?
        res
      else
        Success.new(nil, 0)
      end
    end
  end

  class Any
    def parse(input)
      if input.size > 0
        Success.new(input[0], 1)
      else
        Failure.new
      end
    end
  end

  # Is this the right thing to do for empty
  # rules? I'm not sure.
  class Never
    def parse(input)
      Failure.new
    end
  end

  class And
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def parse(input)
      res = value.parse(input)

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

    def parse(input)
      res = value.parse(input)

      if res.success?
        Failure.new
      else
        Success.new(nil, 0)
      end
    end
  end

  class Apply
    @@indent = 0

    attr_reader :grammar, :rule

    def initialize(grammar, rule)
      @grammar = grammar
      @rule = rule
    end

    def parse(input)
      debug(input) do
        res = grammar.send(rule).parse(input)

        if res.success? && grammar.actions&.respond_to?(rule)
          res.value = grammar.actions.send(rule, *Array(res.value))
        end

        res
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

