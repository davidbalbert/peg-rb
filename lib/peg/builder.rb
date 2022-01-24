require 'peg/refinements'
require 'peg/runtime'
require 'peg/grammar'
require 'peg/semantics'
require 'peg/built_in_rules'
require 'peg/parser'

require 'peg/codegen'

module Peg
  using Constantize
  using Indentation

  class Builder
    class Visitor < Semantics[Parser]
      def_operation :to_rb do |builder, class_name=nil|
        def Grammar(name, super_grammar, _, defs, _, _)
          grammar = class_name || name.visit(builder)

          if !super_grammar.children.empty?
            super_grammar = super_grammar.children[0].visit(builder)
          else
            super_grammar = Peg::BuiltInRules
          end

          defs.children.each do |d|
            d.visit(builder)
          end

          <<~RUBY
            class #{grammar} < #{super_grammar.name}
              self.default_rule = :#{builder.rules.first&.name}

            #{
              builder.rules.map do |rule|
                rule.to_rb.indent(2)
              end.join("\n\n")
            }
            end
          RUBY
        end
      end

      def_operation :visit do |builder|
        def Grammar(name, super_grammar, _, defs, _, _)
          if !super_grammar.children.empty?
            super_grammar = super_grammar.children[0].visit(builder)
          else
            super_grammar = Peg::BuiltInRules
          end

          rules = defs.children.each do |d|
            d.visit(builder)
          end

          grammar = Class.new(super_grammar) do
            self.default_rule = rules.first&.name
          end

          builder.rules.each do |rule|
            grammar.class_eval(rule.to_rb)
          end

          grammar
        end

        def SuperGrammar(_, name)
          name.visit(builder).constantize(builder.namespace)
        end

        def Definition_define(n, _, rules)
          name = n.visit(builder)
          builder.current_rule_name = name

          builder.declare_rule(name)
          body = rules.visit(builder)
          builder.def_rule(name, body)
        end

        def Definition_extend(n, _, expr)
          name = n.visit(builder)

          builder.declare_rule(name)

          body = Choice.new(
            expr.visit(builder),
            Super.new(name),
          )

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

          builder.declare_rule(name)
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

        def Primary_any(_)
          Peg::Any.new
        end

        def identifier(start, rest)
          start.visit(builder) + rest.children.map { |c| c.visit(builder) }.join
        end

        def literal(_, chars, _)
          Term.new(chars.children.map { |c| c.visit(builder) }.join)
        end

        def charClass(_, ranges, _)
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

        def char_unicode(_, h1, h2, h3, h4, h5, h6)
          digits = [h1, h2, h3, h4, h5, h6]
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

        def _terminal
          source_string
        end
      end
    end

    attr_reader :source, :namespace
    attr_accessor :current_rule_name

    def initialize(source, namespace:)
      @source = source
      @namespace = namespace
      @rules = {}
      @rule_names = []
    end

    def build
      result = Peg::Parser.parse(source)

      raise "Couldn't parse" if result.fail?

      Visitor.wrap(result).visit(self)
    end

    def to_rb(class_name)
      result = Peg::Parser.parse(source)

      raise "Couldn't parse" if result.fail?

      Visitor.wrap(result).to_rb(self, class_name)
    end

    def declare_rule(name)
      @rule_names << name
    end

    def def_rule(name, body)
      @rules[name] = Rule.new(name, body)
    end

    def rules
      @rule_names.map { |name| @rules[name] }
    end
  end
end
