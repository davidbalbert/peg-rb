# Generated by: bin/compile lib/peg/parser.peg Peg::Parser -o lib/peg/parser.rb
# Do not edit. Edit lib/peg/parser.peg instead.

require 'peg/grammar'
require 'peg/runtime'

class Peg::Parser < Peg::BuiltInRules
  self.default_rule = :grammar
  self.rules = [:grammar, :superGrammar, :definition, :inlineRules, :expression, :namedSequence, :namedSequence_inline, :sequence, :prefix, :prefix_and, :prefix_not, :suffix, :suffix_maybe, :suffix_star, :suffix_plus, :primary, :primary_identifier, :primary_group, :identifier, :identStart, :identCont, :literal, :charClass, :range, :range_multiple, :char, :char_backslash, :char_doubleQuote, :char_singleQuote, :char_openSquare, :char_closeSquare, :char_backspace, :char_newline, :char_carriageReturn, :char_tab, :char_unicode, :char_hex, :char_regular, :hex, :leftArrow, :slash, :and, :not, :query, :star, :plus, :open, :close, :dot, :dashes, :spacing, :comment, :space, :endOfLine, :endOfFile]

  def grammar
    Peg::Seq.new(
      Peg::Apply.new(:spacing),
      Peg::Apply.new(:identifier),
      Peg::Apply.new(:spacing),
      Peg::Maybe.new(
        Peg::Apply.new(:superGrammar)
      ),
      Peg::Apply.new(:spacing),
      Peg::Term.new("{"),
      Peg::Apply.new(:spacing),
      Peg::OneOrMore.new(
        Peg::Apply.new(:definition)
      ),
      Peg::Apply.new(:spacing),
      Peg::Term.new("}"),
      Peg::Apply.new(:spacing),
      Peg::Apply.new(:endOfFile)
    )
  end

  def superGrammar
    Peg::Seq.new(
      Peg::Term.new("<:"),
      Peg::Apply.new(:spacing),
      Peg::Apply.new(:identifier)
    )
  end

  def definition
    Peg::Seq.new(
      Peg::Apply.new(:identifier),
      Peg::Apply.new(:leftArrow),
      Peg::Apply.new(:inlineRules)
    )
  end

  def inlineRules
    Peg::Seq.new(
      Peg::Apply.new(:namedSequence),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Apply.new(:slash),
          Peg::Apply.new(:namedSequence)
        )
      )
    )
  end

  def expression
    Peg::Seq.new(
      Peg::Apply.new(:sequence),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Apply.new(:slash),
          Peg::Apply.new(:sequence)
        )
      )
    )
  end

  def namedSequence
    Peg::Choice.new(
      Peg::Apply.new(:namedSequence_inline),
      Peg::Apply.new(:sequence)
    )
  end

  def namedSequence_inline
    Peg::Seq.new(
      Peg::Apply.new(:sequence),
      Peg::Apply.new(:dashes),
      Peg::Apply.new(:identifier)
    )
  end

  def sequence
    Peg::ZeroOrMore.new(
      Peg::Apply.new(:prefix)
    )
  end

  def prefix
    Peg::Choice.new(
      Peg::Apply.new(:prefix_and),
      Peg::Apply.new(:prefix_not),
      Peg::Apply.new(:suffix)
    )
  end

  def prefix_and
    Peg::Seq.new(
      Peg::Apply.new(:and),
      Peg::Apply.new(:suffix)
    )
  end

  def prefix_not
    Peg::Seq.new(
      Peg::Apply.new(:not),
      Peg::Apply.new(:suffix)
    )
  end

  def suffix
    Peg::Choice.new(
      Peg::Apply.new(:suffix_maybe),
      Peg::Apply.new(:suffix_star),
      Peg::Apply.new(:suffix_plus),
      Peg::Apply.new(:primary)
    )
  end

  def suffix_maybe
    Peg::Seq.new(
      Peg::Apply.new(:primary),
      Peg::Apply.new(:query)
    )
  end

  def suffix_star
    Peg::Seq.new(
      Peg::Apply.new(:primary),
      Peg::Apply.new(:star)
    )
  end

  def suffix_plus
    Peg::Seq.new(
      Peg::Apply.new(:primary),
      Peg::Apply.new(:plus)
    )
  end

  def primary
    Peg::Choice.new(
      Peg::Apply.new(:primary_identifier),
      Peg::Apply.new(:primary_group),
      Peg::Apply.new(:literal),
      Peg::Apply.new(:charClass),
      Peg::Apply.new(:dot)
    )
  end

  def primary_identifier
    Peg::Seq.new(
      Peg::Apply.new(:identifier),
      Peg::Not.new(
        Peg::Apply.new(:leftArrow)
      )
    )
  end

  def primary_group
    Peg::Seq.new(
      Peg::Apply.new(:open),
      Peg::Apply.new(:expression),
      Peg::Apply.new(:close)
    )
  end

  def identifier
    Peg::Seq.new(
      Peg::Apply.new(:identStart),
      Peg::ZeroOrMore.new(
        Peg::Apply.new(:identCont)
      ),
      Peg::Apply.new(:spacing)
    )
  end

  def identStart
    Peg::CharSet.new("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
  end

  def identCont
    Peg::Choice.new(
      Peg::Apply.new(:identStart),
      Peg::CharSet.new("0123456789")
    )
  end

  def literal
    Peg::Choice.new(
      Peg::Seq.new(
        Peg::CharSet.new("'"),
        Peg::ZeroOrMore.new(
          Peg::Seq.new(
            Peg::Not.new(
              Peg::CharSet.new("'")
            ),
            Peg::Apply.new(:char)
          )
        ),
        Peg::CharSet.new("'"),
        Peg::Apply.new(:spacing)
      ),
      Peg::Seq.new(
        Peg::CharSet.new("\""),
        Peg::ZeroOrMore.new(
          Peg::Seq.new(
            Peg::Not.new(
              Peg::CharSet.new("\"")
            ),
            Peg::Apply.new(:char)
          )
        ),
        Peg::CharSet.new("\""),
        Peg::Apply.new(:spacing)
      )
    )
  end

  def charClass
    Peg::Seq.new(
      Peg::Term.new("["),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Not.new(
            Peg::Term.new("]")
          ),
          Peg::Apply.new(:range)
        )
      ),
      Peg::Term.new("]"),
      Peg::Apply.new(:spacing)
    )
  end

  def range
    Peg::Choice.new(
      Peg::Apply.new(:range_multiple),
      Peg::Apply.new(:char)
    )
  end

  def range_multiple
    Peg::Seq.new(
      Peg::Apply.new(:char),
      Peg::Term.new("-"),
      Peg::Apply.new(:char)
    )
  end

  def char
    Peg::Choice.new(
      Peg::Apply.new(:char_backslash),
      Peg::Apply.new(:char_doubleQuote),
      Peg::Apply.new(:char_singleQuote),
      Peg::Apply.new(:char_openSquare),
      Peg::Apply.new(:char_closeSquare),
      Peg::Apply.new(:char_backspace),
      Peg::Apply.new(:char_newline),
      Peg::Apply.new(:char_carriageReturn),
      Peg::Apply.new(:char_tab),
      Peg::Apply.new(:char_unicode),
      Peg::Apply.new(:char_hex),
      Peg::Apply.new(:char_regular)
    )
  end

  def char_backslash
    Peg::Term.new("\\\\")
  end

  def char_doubleQuote
    Peg::Term.new("\\\"")
  end

  def char_singleQuote
    Peg::Term.new("\\'")
  end

  def char_openSquare
    Peg::Term.new("\\[")
  end

  def char_closeSquare
    Peg::Term.new("\\]")
  end

  def char_backspace
    Peg::Term.new("\\b")
  end

  def char_newline
    Peg::Term.new("\\n")
  end

  def char_carriageReturn
    Peg::Term.new("\\r")
  end

  def char_tab
    Peg::Term.new("\\t")
  end

  def char_unicode
    Peg::Seq.new(
      Peg::Term.new("\\u"),
      Peg::Apply.new(:hex),
      Peg::Apply.new(:hex),
      Peg::Apply.new(:hex),
      Peg::Apply.new(:hex)
    )
  end

  def char_hex
    Peg::Seq.new(
      Peg::Term.new("\\x"),
      Peg::Apply.new(:hex),
      Peg::Apply.new(:hex)
    )
  end

  def char_regular
    Peg::Seq.new(
      Peg::Not.new(
        Peg::Term.new("\\")
      ),
      Peg::Any.new
    )
  end

  def hex
    Peg::CharSet.new("0123456789abcdefABCDEF")
  end

  def leftArrow
    Peg::Seq.new(
      Peg::Term.new("<-"),
      Peg::Apply.new(:spacing)
    )
  end

  def slash
    Peg::Seq.new(
      Peg::Term.new("/"),
      Peg::Apply.new(:spacing)
    )
  end

  def and
    Peg::Seq.new(
      Peg::Term.new("&"),
      Peg::Apply.new(:spacing)
    )
  end

  def not
    Peg::Seq.new(
      Peg::Term.new("!"),
      Peg::Apply.new(:spacing)
    )
  end

  def query
    Peg::Seq.new(
      Peg::Term.new("?"),
      Peg::Apply.new(:spacing)
    )
  end

  def star
    Peg::Seq.new(
      Peg::Term.new("*"),
      Peg::Apply.new(:spacing)
    )
  end

  def plus
    Peg::Seq.new(
      Peg::Term.new("+"),
      Peg::Apply.new(:spacing)
    )
  end

  def open
    Peg::Seq.new(
      Peg::Term.new("("),
      Peg::Apply.new(:spacing)
    )
  end

  def close
    Peg::Seq.new(
      Peg::Term.new(")"),
      Peg::Apply.new(:spacing)
    )
  end

  def dot
    Peg::Seq.new(
      Peg::Term.new("."),
      Peg::Apply.new(:spacing)
    )
  end

  def dashes
    Peg::Seq.new(
      Peg::Term.new("--"),
      Peg::Apply.new(:spacing)
    )
  end

  def spacing
    Peg::ZeroOrMore.new(
      Peg::Choice.new(
        Peg::Apply.new(:space),
        Peg::Apply.new(:comment)
      )
    )
  end

  def comment
    Peg::Seq.new(
      Peg::Term.new("#"),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Not.new(
            Peg::Apply.new(:endOfLine)
          ),
          Peg::Any.new
        )
      ),
      Peg::Apply.new(:endOfLine)
    )
  end

  def space
    Peg::Choice.new(
      Peg::Term.new(" "),
      Peg::Term.new("\t"),
      Peg::Apply.new(:endOfLine)
    )
  end

  def endOfLine
    Peg::Choice.new(
      Peg::Term.new("\r\n"),
      Peg::Term.new("\n"),
      Peg::Term.new("\r")
    )
  end

  def endOfFile
    Peg::Not.new(
      Peg::Any.new
    )
  end
end
