class Peg::Parser < Peg::Grammar
  self.default_rule = :Grammar

  def Grammar
    Peg::Seq.new(
      Peg::Apply.new(:Spacing),
      Peg::OneOrMore.new(
        Peg::Apply.new(:Definition)
      ),
      Peg::Apply.new(:EndOfFile)
    )
  end

  def Definition
    Peg::Seq.new(
      Peg::Apply.new(:Identifier),
      Peg::Apply.new(:LEFTARROW),
      Peg::Apply.new(:InlineRules)
    )
  end

  def InlineRules
    Peg::Seq.new(
      Peg::Apply.new(:NamedSequence),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Apply.new(:SLASH),
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
          Peg::Apply.new(:SLASH),
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
      Peg::Apply.new(:DASHES),
      Peg::Apply.new(:Identifier)
    )
  end

  def Sequence
    Peg::OneOrMore.new(
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
      Peg::Apply.new(:AND),
      Peg::Apply.new(:Suffix)
    )
  end

  def Prefix_not
    Peg::Seq.new(
      Peg::Apply.new(:NOT),
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
      Peg::Apply.new(:QUERY)
    )
  end

  def Suffix_star
    Peg::Seq.new(
      Peg::Apply.new(:Primary),
      Peg::Apply.new(:STAR)
    )
  end

  def Suffix_plus
    Peg::Seq.new(
      Peg::Apply.new(:Primary),
      Peg::Apply.new(:PLUS)
    )
  end

  def Primary
    Peg::Choice.new(
      Peg::Apply.new(:Primary_identifier),
      Peg::Apply.new(:Primary_group),
      Peg::Apply.new(:Literal),
      Peg::Apply.new(:Class),
      Peg::Apply.new(:DOT)
    )
  end

  def Primary_identifier
    Peg::Seq.new(
      Peg::Apply.new(:Identifier),
      Peg::Not.new(
        Peg::Apply.new(:LEFTARROW)
      )
    )
  end

  def Primary_group
    Peg::Seq.new(
      Peg::Apply.new(:OPEN),
      Peg::Apply.new(:Expression),
      Peg::Apply.new(:CLOSE)
    )
  end

  def Identifier
    Peg::Seq.new(
      Peg::Apply.new(:IdentStart),
      Peg::ZeroOrMore.new(
        Peg::Apply.new(:IdentCont)
      ),
      Peg::Apply.new(:Spacing)
    )
  end

  def IdentStart
    Peg::CharSet.new("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
  end

  def IdentCont
    Peg::Choice.new(
      Peg::Apply.new(:IdentStart),
      Peg::CharSet.new("0123456789")
    )
  end

  def Literal
    Peg::Choice.new(
      Peg::Seq.new(
        Peg::CharSet.new("'"),
        Peg::ZeroOrMore.new(
          Peg::Seq.new(
            Peg::Not.new(
              Peg::CharSet.new("'")
            ),
            Peg::Apply.new(:Char)
          )
        ),
        Peg::CharSet.new("'"),
        Peg::Apply.new(:Spacing)
      ),
      Peg::Seq.new(
        Peg::CharSet.new("\""),
        Peg::ZeroOrMore.new(
          Peg::Seq.new(
            Peg::Not.new(
              Peg::CharSet.new("\"")
            ),
            Peg::Apply.new(:Char)
          )
        ),
        Peg::CharSet.new("\""),
        Peg::Apply.new(:Spacing)
      )
    )
  end

  def Class
    Peg::Seq.new(
      Peg::Term.new("["),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Not.new(
            Peg::Term.new("]")
          ),
          Peg::Apply.new(:Range)
        )
      ),
      Peg::Term.new("]"),
      Peg::Apply.new(:Spacing)
    )
  end

  def Range
    Peg::Choice.new(
      Peg::Apply.new(:Range_multiple),
      Peg::Apply.new(:Char)
    )
  end

  def Range_multiple
    Peg::Seq.new(
      Peg::Apply.new(:Char),
      Peg::Term.new("-"),
      Peg::Apply.new(:Char)
    )
  end

  def Char
    Peg::Choice.new(
      Peg::Apply.new(:Char_backslash),
      Peg::Apply.new(:Char_doubleQuote),
      Peg::Apply.new(:Char_singleQuote),
      Peg::Apply.new(:Char_openSquare),
      Peg::Apply.new(:Char_closeSquare),
      Peg::Apply.new(:Char_backspace),
      Peg::Apply.new(:Char_newline),
      Peg::Apply.new(:Char_carriageReturn),
      Peg::Apply.new(:Char_tab),
      Peg::Apply.new(:Char_unicode),
      Peg::Apply.new(:Char_hex),
      Peg::Apply.new(:Char_regular)
    )
  end

  def Char_backslash
    Peg::Term.new("\\\\")
  end

  def Char_doubleQuote
    Peg::Term.new("\\\"")
  end

  def Char_singleQuote
    Peg::Term.new("\\'")
  end

  def Char_openSquare
    Peg::Term.new("\\[")
  end

  def Char_closeSquare
    Peg::Term.new("\\]")
  end

  def Char_backspace
    Peg::Term.new("\\b")
  end

  def Char_newline
    Peg::Term.new("\\n")
  end

  def Char_carriageReturn
    Peg::Term.new("\\r")
  end

  def Char_tab
    Peg::Term.new("\\t")
  end

  def Char_unicode
    Peg::Seq.new(
      Peg::Term.new("\\u"),
      Peg::Apply.new(:Hex),
      Peg::Apply.new(:Hex),
      Peg::Apply.new(:Hex),
      Peg::Apply.new(:Hex)
    )
  end

  def Char_hex
    Peg::Seq.new(
      Peg::Term.new("\\x"),
      Peg::Apply.new(:Hex),
      Peg::Apply.new(:Hex)
    )
  end

  def Char_regular
    Peg::Seq.new(
      Peg::Not.new(
        Peg::Term.new("\\")
      ),
      Peg::Any.new
    )
  end

  def Hex
    Peg::CharSet.new("0123456789abcdefABCDEF")
  end

  def LEFTARROW
    Peg::Seq.new(
      Peg::Term.new("<-"),
      Peg::Apply.new(:Spacing)
    )
  end

  def SLASH
    Peg::Seq.new(
      Peg::Term.new("/"),
      Peg::Apply.new(:Spacing)
    )
  end

  def AND
    Peg::Seq.new(
      Peg::Term.new("&"),
      Peg::Apply.new(:Spacing)
    )
  end

  def NOT
    Peg::Seq.new(
      Peg::Term.new("!"),
      Peg::Apply.new(:Spacing)
    )
  end

  def QUERY
    Peg::Seq.new(
      Peg::Term.new("?"),
      Peg::Apply.new(:Spacing)
    )
  end

  def STAR
    Peg::Seq.new(
      Peg::Term.new("*"),
      Peg::Apply.new(:Spacing)
    )
  end

  def PLUS
    Peg::Seq.new(
      Peg::Term.new("+"),
      Peg::Apply.new(:Spacing)
    )
  end

  def OPEN
    Peg::Seq.new(
      Peg::Term.new("("),
      Peg::Apply.new(:Spacing)
    )
  end

  def CLOSE
    Peg::Seq.new(
      Peg::Term.new(")"),
      Peg::Apply.new(:Spacing)
    )
  end

  def DOT
    Peg::Seq.new(
      Peg::Term.new("."),
      Peg::Apply.new(:Spacing)
    )
  end

  def DASHES
    Peg::Seq.new(
      Peg::Term.new("--"),
      Peg::Apply.new(:Spacing)
    )
  end

  def Spacing
    Peg::ZeroOrMore.new(
      Peg::Choice.new(
        Peg::Apply.new(:Space),
        Peg::Apply.new(:Comment)
      )
    )
  end

  def Comment
    Peg::Seq.new(
      Peg::Term.new("#"),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Not.new(
            Peg::Apply.new(:EndOfLine)
          ),
          Peg::Any.new
        )
      ),
      Peg::Apply.new(:EndOfLine)
    )
  end

  def Space
    Peg::Choice.new(
      Peg::Term.new(" "),
      Peg::Term.new("\t"),
      Peg::Apply.new(:EndOfLine)
    )
  end

  def EndOfLine
    Peg::Choice.new(
      Peg::Term.new("\r\n"),
      Peg::Term.new("\n"),
      Peg::Term.new("\r")
    )
  end

  def EndOfFile
    Peg::Not.new(
      Peg::Any.new
    )
  end
end
