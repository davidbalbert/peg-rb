module Peg
  module Indentation
    refine String do
      def indent(n)
        split("\n").map { |l| " "*n + l }.join("\n")
      end
    end
  end

  using Indentation

  module AST
    class Leaf
      def self.[](*attrs)
        Class.new(Leaf) do
          attr_reader(*attrs)

          define_method :initialize do |*args|
            if args.size != attrs.size
              raise ArgumentError, "wrong number of arguments (given #{args.size}, expected #{attrs.size})"
            end

            attrs.zip(args).each do |name, value|
              instance_variable_set :"@#{name}", value
            end
          end
        end
      end

      def children
        []
      end

      def transform_children
        self
      end
    end

    class Unary
      attr_reader :value

      def self.[](attr)
        Class.new(Unary) do
          define_method attr do
            @value
          end
        end
      end

      def initialize(value)
        @value = value
      end

      def children
        [value]
      end

      def transform_children
        self.class.new(yield(value))
      end
    end

    class NAry
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def transform_children
        new_children = children.map { |c| yield(c) }

        self.class.new(new_children)
      end
    end

    class Grammar < NAry
      attr_reader :class_name

      def initialize(class_name, children)
        super(children)
        @class_name = class_name
      end

      alias rules children

      def to_rb
        <<~RUBY
          class #{class_name} < Peg::Grammar
            def root
              Peg::Apply.new(self, :#{rules.first.name})
            end

          #{rules.map {|r| r.to_rb.indent(2)}.join("\n\n")}
          end
        RUBY
      end
    end

    class Rule < Unary[:body]
      attr_reader :name

      def initialize(name, body)
        super(body)
        @name = name
      end

      def to_rb
        <<~RUBY
          def #{name}
          #{body.to_rb.indent(2)}
          end
        RUBY
      end
    end

    class Choice < NAry
      def to_rb
        <<~RUBY
          Peg::Choice.new(
          #{children.map {|o| o.to_rb.indent(2)}.join(",\n")}
          )
        RUBY
      end
    end

    class NamedSeq < Unary[:seq]
      attr_reader :name

      def initialize(name, seq)
        super(seq)
        @name = name
      end

      def to_rb
        Apply.new(name.to_sym).to_rb
      end

      def with_parent_name(parent_name)
        NamedSeq.new(parent_name + "_" + name, seq)
      end
    end

    class Seq < NAry
      def to_rb
        <<~RUBY
          Peg::Seq.new(
          #{children.map {|e| e.to_rb.indent(2)}.join(",\n")}
          )
        RUBY
      end
    end

    class CharSet < Leaf[:chars]
      def to_rb
        <<~RUBY
          Peg::CharSet.new(#{chars.inspect})
        RUBY
      end
    end

    class ZeroOrMore < Unary[:value]
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def to_rb
        <<~RUBY
          Peg::ZeroOrMore.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    class OneOrMore < Unary[:value]
      def to_rb
        <<~RUBY
          Peg::OneOrMore.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    class Maybe < Unary[:value]
      def to_rb
        <<~RUBY
          Peg::Maybe.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    class Any < Leaf
      def to_rb
        <<~RUBY
          Peg::Any.new
        RUBY
      end
    end

    class Never < Leaf
      def to_rb
        <<~RUBY
          Peg::Never.new
        RUBY
      end
    end

    class And < Unary[:value]
      def to_rb
        <<~RUBY
          Peg::And.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    class Not < Unary[:value]
      def to_rb
        <<~RUBY
          Peg::Not.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    class Apply < Unary[:rule]
      def to_rb
        <<~RUBY
          Peg::Apply.new(self, :#{rule})
        RUBY
      end
    end

    class Term < Leaf[:value]
      def to_rb
        <<~RUBY
          Peg::Term.new(#{value.inspect})
        RUBY
      end
    end
  end

  class Generator
    attr_reader :class_name

    def initialize(class_name)
      @class_name = class_name
    end

    def Grammar(spacing, rules, eof)
      AST::Grammar.new(class_name, rules.flatten)
    end

    def Definition(name, _, inline_rules)
      body = inline_rules.transform_children do |s|
        if s.respond_to?(:with_parent_name)
          s.with_parent_name(name)
        else
          s
        end
      end

      new_rules = body.children.select {|s| s.is_a? AST::NamedSeq }.map do |ns|
        AST::Rule.new(ns.name, ns.seq)
      end

      unless new_rules.empty?
        [AST::Rule.new(name, body), *new_rules]
      else
        AST::Rule.new(name, body)
      end
    end

    def InlineRules(named_seq, named_seqs)
      # named_seqs: [('/', AST node)...]

      if named_seqs.empty?
        named_seq
      else
        AST::Choice.new([named_seq, *named_seqs.map {|(_, c)| c}])
      end
    end

    def Expression(seq, seqs)
      # seqs: [('/', AST node)...]

      if seqs.empty?
        seq
      else
        AST::Choice.new([seq, *seqs.map {|(_, c)| c}])
      end
    end

    def NamedSequence(sequence, name)
      # name: ('--', String)?
      if name
        name = name[1]
      end

      if name
        AST::NamedSeq.new(name, sequence)
      else
        sequence
      end
    end

    def Sequence(prefixes)
      case prefixes.size
      when 0
        AST::Never.new
      when 1
        prefixes[0]
      else
        AST::Seq.new(prefixes)
      end
    end

    def Prefix(prefix, suffix)
      case prefix
      when "&"
        AST::And.new(suffix)
      when "!"
        AST::Not.new(suffix)
      when nil
        suffix
      else
        raise "Invalid prefix: #{prefix}"
      end
    end

    def Suffix(primary, suffix)
      case suffix
      when "?"
        AST::Maybe.new(primary)
      when "*"
        AST::ZeroOrMore.new(primary)
      when "+"
        AST::OneOrMore.new(primary)
      when nil
        primary
      else
        raise "Invalid suffix: #{suffix}"
      end
    end

    def Primary_identifier(id, _)
      AST::Apply.new(id)
    end

    def Primary_group(_, expr, _)
      expr
    end

    def Identifier(start, cont, _)
      start + cont.join
    end

    def Literal(_, chars, _, _)
      # chars: [(nil, String)...]
      AST::Term.new(chars.map {|(_, c)| c }.join)
    end

    def Class(_, ranges, _, _)
      # ranges: [(nil, String)...]
      AST::CharSet.new(ranges.map {|(_, c)| c }.join)
    end

    def Range_multiple(first, _, last)
      (first..last).to_a.join
    end

    def Char_backslash(_)
      "\\"
    end

    def Char_doubleQuote(_)
      '"'
    end

    def Char_singleQuote(_)
      "'"
    end

    def Char_openSquare(_)
      "["
    end

    def Char_closeSquare(_)
      "]"
    end

    def Char_backspace(_)
      "\b"
    end

    def Char_newline(_)
      "\n"
    end

    def Char_carriageReturn(_)
      "\r"
    end

    def Char_tab(_)
      "\t"
    end

    def Char_unicode(_, h1, h2, h3, h4)
      ("0x"+h1+h2+h3+h4).to_i(16).chr(Encoding::UTF_8)
    end

    def Char_hex(_, h1, h2)
      ("0x"+h1+h2).to_i(16).chr
    end

    def Char_regular(_, c)
      c
    end

    def LEFTARROW(arrow, _)
      arrow
    end

    def SLASH(slash, _)
      slash
    end

    def AND(amp, _)
      amp
    end

    def NOT(bang, _)
      bang
    end

    def QUERY(query, _)
      query
    end

    def STAR(star, _)
      star
    end

    def PLUS(plus, _)
      plus
    end

    def OPEN(open, _)
      open
    end

    def CLOSE(close, _)
      close
    end

    def DOT(_, _)
      AST::Any.new
    end

    def DASHES(dashes, _)
      dashes
    end
  end
end
