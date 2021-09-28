class Peg
  module Indentation
    refine String do
      def indent(n)
        split("\n").map { |l| " "*n + l }.join("\n")
      end
    end
  end

  using Indentation

  module AST
    Grammar = Struct.new(:rules) do
      def to_rb
        <<~RUBY
          class G
            def root
              Peg::Apply.new(self, :#{rules.first.name})
            end

          #{rules.map {|r| r.to_rb.indent(2)}.join("\n\n")}
          end
        RUBY
      end
    end

    Rule = Struct.new(:name, :body) do
      def to_rb
        <<~RUBY
          def #{name}
          #{body.to_rb.indent(2)}
          end
        RUBY
      end
    end

    Choice = Struct.new(:options) do
      def to_rb
        <<~RUBY
          Peg::Choice.new(
          #{options.map {|o| o.to_rb.indent(2)}.join(",\n")}
          )
        RUBY
      end
    end

    Seq = Struct.new(:exps) do
      def to_rb
        <<~RUBY
          Peg::Seq.new(
          #{exps.map {|e| e.to_rb.indent(2)}.join(",\n")}
          )
        RUBY
      end
    end

    CharSet = Struct.new(:chars) do
      def to_rb
        <<~RUBY
          Peg::CharSet.new(#{chars.inspect})
        RUBY
      end
    end

    ZeroOrMore = Struct.new(:value) do
      def to_rb
        <<~RUBY
          Peg::ZeroOrMore.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    OneOrMore = Struct.new(:value) do
      def to_rb
        <<~RUBY
          Peg::OneOrMore.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    Maybe = Struct.new(:value) do
      def to_rb
        <<~RUBY
          Peg::Maybe.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    class Any
      def to_rb
        <<~RUBY
          Peg::Any.new
        RUBY
      end
    end

    class Never
      def to_rb
        <<~RUBY
          Peg::Never.new
        RUBY
      end
    end

    And = Struct.new(:value) do
      def to_rb
        <<~RUBY
          Peg::And.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end


    Not = Struct.new(:value) do
      def to_rb
        <<~RUBY
          Peg::Not.new(
          #{value.to_rb.indent(2)}
          )
        RUBY
      end
    end

    Apply = Struct.new(:rule) do
      def to_rb
        <<~RUBY
          Peg::Apply.new(self, :#{rule})
        RUBY
      end
    end

    Term = Struct.new(:value) do
      def to_rb
        <<~RUBY
          Peg::Term.new(#{value.inspect})
        RUBY
      end
    end
  end

  class Generator
    def Grammar(spacing, rules, eof)
      AST::Grammar.new(rules)
    end

    def Definition(name, _, expression)
      AST::Rule.new(name, expression)
    end

    def Expression(choice, choices)
      # choices: [('/', String)...]

      if choices.empty?
        choice
      else
        AST::Choice.new([choice, *choices.map {|(_, c)| c}])
      end
    end

    def Choice(seq, rule_name)
      # rule_name: ('--', String)?
      if rule_name
        rule_name = rule_name[1]
      end

      # TODO: use rule_name

      seq
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
