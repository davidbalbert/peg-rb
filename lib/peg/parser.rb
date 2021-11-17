# Generated by: bin/compile lib/peg/parser.peg Peg::Parser -o lib/peg/parser.rb
# Do not edit. Edit lib/peg/parser.peg instead.

require 'peg/grammar'
require 'peg/runtime'

class Peg::Parser < Peg::BuiltInRules
  self.default_rule = :Grammar
  self.rules = [:Grammar, :SuperGrammar, :Definition, :Definition_define, :Definition_extend, :InlineRules, :Expression, :NamedSequence, :NamedSequence_inline, :Sequence, :Prefix, :Prefix_and, :Prefix_not, :Suffix, :Suffix_maybe, :Suffix_star, :Suffix_plus, :Primary, :Primary_identifier, :Primary_group, :Primary_any, :identifier, :identStart, :identCont, :literal, :charClass, :range, :range_multiple, :char, :char_backslash, :char_doubleQuote, :char_singleQuote, :char_openSquare, :char_closeSquare, :char_backspace, :char_newline, :char_carriageReturn, :char_tab, :char_unicode, :char_hex, :char_regular, :hex, :space, :comment, :endOfLine, :endOfFile]

  def Grammar
    Peg::Seq.new(
      Peg::Apply.new(:identifier),
      Peg::Maybe.new(
        Peg::Apply.new(:SuperGrammar)
      ),
      Peg::Term.new("{"),
      Peg::OneOrMore.new(
        Peg::Apply.new(:Definition)
      ),
      Peg::Term.new("}"),
      Peg::Apply.new(:endOfFile)
    )
  end

  def SuperGrammar
    Peg::Seq.new(
      Peg::Term.new("<:"),
      Peg::Apply.new(:identifier)
    )
  end

  def Definition
    Peg::Choice.new(
      Peg::Apply.new(:Definition_define),
      Peg::Apply.new(:Definition_extend)
    )
  end

  def Definition_define
    Peg::Seq.new(
      Peg::Apply.new(:identifier),
      Peg::Term.new("<-"),
      Peg::Apply.new(:InlineRules)
    )
  end

  def Definition_extend
    Peg::Seq.new(
      Peg::Apply.new(:identifier),
      Peg::Term.new("+="),
      Peg::Apply.new(:Expression)
    )
  end

  def InlineRules
    Peg::Seq.new(
      Peg::Apply.new(:NamedSequence),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Term.new("/"),
          Peg::Apply.new(:NamedSequence)
        )
      )
    )
  end

  def Expression
    Peg::Seq.new(
      Peg::Apply.new(:Sequence),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Term.new("/"),
          Peg::Apply.new(:Sequence)
        )
      )
    )
  end

  def NamedSequence
    Peg::Choice.new(
      Peg::Apply.new(:NamedSequence_inline),
      Peg::Apply.new(:Sequence)
    )
  end

  def NamedSequence_inline
    Peg::Seq.new(
      Peg::Apply.new(:Sequence),
      Peg::Term.new("--"),
      Peg::Apply.new(:identifier)
    )
  end

  def Sequence
    Peg::ZeroOrMore.new(
      Peg::Apply.new(:Prefix)
    )
  end

  def Prefix
    Peg::Choice.new(
      Peg::Apply.new(:Prefix_and),
      Peg::Apply.new(:Prefix_not),
      Peg::Apply.new(:Suffix)
    )
  end

  def Prefix_and
    Peg::Seq.new(
      Peg::Term.new("&"),
      Peg::Apply.new(:Suffix)
    )
  end

  def Prefix_not
    Peg::Seq.new(
      Peg::Term.new("!"),
      Peg::Apply.new(:Suffix)
    )
  end

  def Suffix
    Peg::Choice.new(
      Peg::Apply.new(:Suffix_maybe),
      Peg::Apply.new(:Suffix_star),
      Peg::Apply.new(:Suffix_plus),
      Peg::Apply.new(:Primary)
    )
  end

  def Suffix_maybe
    Peg::Seq.new(
      Peg::Apply.new(:Primary),
      Peg::Term.new("?")
    )
  end

  def Suffix_star
    Peg::Seq.new(
      Peg::Apply.new(:Primary),
      Peg::Term.new("*")
    )
  end

  def Suffix_plus
    Peg::Seq.new(
      Peg::Apply.new(:Primary),
      Peg::Term.new("+")
    )
  end

  def Primary
    Peg::Choice.new(
      Peg::Apply.new(:Primary_identifier),
      Peg::Apply.new(:Primary_group),
      Peg::Apply.new(:literal),
      Peg::Apply.new(:charClass),
      Peg::Apply.new(:Primary_any)
    )
  end

  def Primary_identifier
    Peg::Seq.new(
      Peg::Apply.new(:identifier),
      Peg::Not.new(
        Peg::Term.new("<-")
      ),
      Peg::Not.new(
        Peg::Term.new("+=")
      )
    )
  end

  def Primary_group
    Peg::Seq.new(
      Peg::Term.new("("),
      Peg::Apply.new(:Expression),
      Peg::Term.new(")")
    )
  end

  def Primary_any
    Peg::Term.new(".")
  end

  def identifier
    Peg::Seq.new(
      Peg::Apply.new(:identStart),
      Peg::ZeroOrMore.new(
        Peg::Apply.new(:identCont)
      )
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
        Peg::CharSet.new("'")
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
        Peg::CharSet.new("\"")
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
      Peg::Term.new("]")
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

  def space
    Peg::Choice.new(
      Peg::Apply.new(:comment),
      Peg::Super.new(:space)
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
