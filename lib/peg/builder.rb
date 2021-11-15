require 'peg/runtime'
require 'peg/grammar'
require 'peg/semantics'
require 'peg/parser'

module Peg
  class Builder
    class Visitor < Semantics[Parser]
      def_operation :visit do |builder|
        def grammar(_, defs, _)
          defs.children.each do |d|
            d.visit(builder)
          end

          builder.grammar
        end

        def definition(n, _, rules)
          name = n.visit(builder)
          builder.current_rule_name = name

          builder.declare_rule(name)
          body = rules.visit(builder)
          builder.def_rule(name, body)
        end

        def inlineRules(named_seq, _, named_seqs)
          alts = [named_seq.visit(builder), *named_seqs.children.map { |s| s.visit(builder) }]

          if alts.size == 1
            alts.first
          else
            Choice.new(*alts)
          end
        end

        def expression(seq, _, seqs)
          alts = [seq.visit(builder), *seqs.children.map { |s| s.visit(builder) }]
          if alts.size == 1
            alts.first
          else
            Choice.new(*alts)
          end
        end

        def namedSequence_inline(seq, _, identifier)
          name = builder.current_rule_name + '_' + identifier.visit(builder)

          builder.declare_rule(name)
          builder.def_rule(name, seq.visit(builder))

          Apply.new(name.intern)
        end

        def sequence(prefixes)
          prefixes = prefixes.children.map { |p| p.visit(builder) }

          if prefixes.empty?
            Never.new
          elsif prefixes.size == 1
            prefixes.first
          else
            Seq.new(*prefixes)
          end
        end

        def prefix_and(_, suffix)
          And.new(suffix.visit(builder))
        end

        def prefix_not(_, suffix)
          Not.new(suffix.visit(builder))
        end

        def suffix_maybe(primary, _)
          Maybe.new(primary.visit(builder))
        end

        def suffix_star(primary, _)
          ZeroOrMore.new(primary.visit(builder))
        end

        def suffix_plus(primary, _)
          OneOrMore.new(primary.visit(builder))
        end

        def primary_identifier(id)
          Apply.new(id.visit(builder).intern)
        end

        def primary_group(_, expr, _)
          expr.visit(builder)
        end

        def identifier(start, rest, _)
          start.visit(builder) + rest.children.map { |c| c.visit(builder) }.join
        end

        def literal(_, chars, _, _)
          Peg::Term.new(chars.children.map { |c| c.visit(builder) }.join)
        end

        def charClass(_, ranges, _, _)
          CharSet.new(ranges.children.map { |r| r.visit(builder) }.join)
        end

        def range_multiple(c1, _, c2)
          (c1.visit(builder)..c2.visit(builder)).to_a.join
        end

        def char_backslash(_)
          "\\"
        end

        def char_doubleQuote(_)
          '"'
        end

        def char_singleQuote(_)
          "'"
        end

        def char_openSquare(_)
          "["
        end

        def char_closeSquare(_)
          "]"
        end

        def char_backspace(_)
          "\b"
        end

        def char_newline(_)
          "\n"
        end

        def char_carriageReturn(_)
          "\r"
        end

        def char_tab(_)
          "\t"
        end

        def char_unicode(_, h1, h2, h3, h4)
          digits = [h1, h2, h3, h4]
          hex = "0x" + digits.map { |d| d.visit(builder) }.join

          hex.to_i(16).chr(Encoding::UTF_8)
        end

        def char_hex(_, h1, h2)
          puts 'hmm'
          ("0x" + h1.visit(builder) + h2.visit(builder)).to_i(16).chr
        end

        def char_regular(c)
          c.visit(builder)
        end

        def leftArrow(s, _)
          s.visit(builder)
        end

        def slash(s, _)
          s.visit(builder)
        end

        def and(s, _)
          s.visit(builder)
        end

        def not(s, _)
          s.visit(builder)
        end

        def query(s, _)
          s.visit(builder)
        end

        def star(s, _)
          s.visit(builder)
        end

        def plus(s, _)
          s.visit(builder)
        end

        def open(s, _)
          s.visit(builder)
        end

        def close(s, _)
          s.visit(builder)
        end

        def dot(s, _)
          Peg::Any.new
        end

        def dashes(s, _)
          s.visit(builder)
        end

        def _terminal
          source_string
        end
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

    def declare_rule(name)
      grammar.class_eval do
        rules << name.intern
      end
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
