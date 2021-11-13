module Peg
  class Builder
    Visitor = Peg::Parser.create_semantics.def_operation :visit do |builder|
      def Grammar(_, defs, _)
        defs.children.each do |d|
          d.visit(builder)
        end

        builder.grammar
      end

      def Definition(n, _, rules)
        name = n.visit(builder)
        builder.current_rule_name = name

        body = rules.visit(builder)
        builder.def_rule(name, body)
      end

      def InlineRules(named_seq, _, named_seqs)
        alts = [named_seq.visit(builder), *named_seqs.children.map { |s| s.visit(builder) }]

        if alts.size == 1
          alts.first
        else
          Choice.new(*alts)
        end
      end

      def Expression(seq, _, seqs)
        alts = [seq.visit(builder), *seqs.children.map { |s| s.visit(builder) }]
        if alts.size == 1
          alts.first
        else
          Choice.new(*alts)
        end
      end

      def NamedSequence_inline(seq, _, identifier)
        name = builder.current_rule_name + '_' + identifier.visit(builder)

        builder.def_rule(name, seq.visit(builder))

        Apply.new(name.intern)
      end

      def Sequence(prefixes)
        prefixes = prefixes.children.map { |p| p.visit(builder) }

        if prefixes.empty?
          Never.new
        elsif prefixes.size == 1
          prefixes.first
        else
          Seq.new(*prefixes)
        end
      end

      def Prefix_and(_, suffix)
        And.new(suffix.visit(builder))
      end

      def Prefix_not(_, suffix)
        Not.new(suffix.visit(builder))
      end

      def Suffix_maybe(primary, _)
        Maybe.new(primary.visit(builder))
      end

      def Suffix_star(primary, _)
        ZeroOrMore.new(primary.visit(builder))
      end

      def Suffix_plus(primary, _)
        OneOrMore.new(primary.visit(builder))
      end

      def Primary_identifier(id)
        Apply.new(id.visit(builder).intern)
      end

      def Primary_group(_, expr, _)
        expr.visit(builder)
      end

      def Dot(_)
        Peg::Any.new
      end

      def Identifier(start, rest, _)
        start.visit(builder) + rest.children.map { |c| c.visit(builder) }.join
      end

      def Literal(_, chars, _, _)
        Peg::Term.new(chars.children.map { |c| c.visit(builder) }.join)
      end

      def Class(_, ranges, _, _)
        CharSet.new(ranges.children.map { |r| r.visit(builder) }.join)
      end

      def Range_multiple(c1, _, c2)
        (c1.visit(builder)..c2.visit(builder)).to_a.join
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
        digits = [h1, h2, h3, h4]
        hex = "0x" + digits.map { |d| d.visit(builder) }.join

        hex.to_i(16).chr(Encoding::UTF_8)
      end

      def Char_hex(_, h1, h2)
        ("0x" + h1.visit(builder) + h2.visit(builder)).to_i(16).chr
      end

      def Char_regular(c)
        c.visit(builder)
      end

      def LEFTARROW(s, _)
        s.visit(builder)
      end

      def SLASH(s, _)
        s.visit(builder)
      end

      def AND(s, _)
        s.visit(builder)
      end

      def NOT(s, _)
        s.visit(builder)
      end

      def QUERY(s, _)
        s.visit(builder)
      end

      def STAR(s, _)
        s.visit(builder)
      end

      def PLUS(s, _)
        s.visit(builder)
      end

      def OPEN(s, _)
        s.visit(builder)
      end

      def CLOSE(s, _)
        s.visit(builder)
      end

      def DOT(s, _)
        Peg::Any.new
      end

      def DASHES(s, _)
        s.visit(builder)
      end

      def Spacing(_)
        nil
      end

      def _non_terminal(*args)
        nil
      end

      def _terminal
        source_string
      end
    end

    attr_reader :source, :grammar, :current_rule_name

    def initialize(source)
      @source = source
      @grammar = Class.new(Peg::Grammar)
      @first = true
    end

    def build
      result = Peg::Parser.parse(source)

      raise "Couldn't parse" if result.fail?

      Visitor.wrap(result).visit(self)
    end

    def current_rule_name=(name)
      if @first
        grammar.class_eval do
          self.default_rule = name.intern
        end

        @first = false
      end

      @current_rule_name = name
    end

    def def_rule(name, body)
      grammar.class_eval do
        define_method name do
          body
        end
      end
    end
  end
end
