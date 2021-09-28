class Peg::Parser < Peg::Grammar
  def root
    Peg::Apply.new(self, :Grammar)
  end

  def Grammar
    Peg::Seq.new(
      Peg::Apply.new(self, :Spacing),
      Peg::OneOrMore.new(
        Peg::Apply.new(self, :Definition)
      ),
      Peg::Apply.new(self, :EndOfFile)
    )
  end

  def Definition
    Peg::Seq.new(
      Peg::Apply.new(self, :Identifier),
      Peg::Apply.new(self, :LEFTARROW),
      Peg::Apply.new(self, :InlineRules)
    )
  end

  def InlineRules
    Peg::Seq.new(
      Peg::Apply.new(self, :NamedSequence),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Apply.new(self, :SLASH),
          Peg::Apply.new(self, :NamedSequence)
        )
      )
    )
  end

  def Expression
    Peg::Seq.new(
      Peg::Apply.new(self, :Sequence),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Apply.new(self, :SLASH),
          Peg::Apply.new(self, :Sequence)
        )
      )
    )
  end

  def NamedSequence
    Peg::Seq.new(
      Peg::Apply.new(self, :Sequence),
      Peg::Maybe.new(
        Peg::Seq.new(
          Peg::Apply.new(self, :DASHES),
          Peg::Apply.new(self, :Identifier)
        )
      )
    )
  end

  def Sequence
    Peg::ZeroOrMore.new(
      Peg::Apply.new(self, :Prefix)
    )
  end

  def Prefix
    Peg::Seq.new(
      Peg::Maybe.new(
        Peg::Choice.new(
          Peg::Apply.new(self, :AND),
          Peg::Apply.new(self, :NOT)
        )
      ),
      Peg::Apply.new(self, :Suffix)
    )
  end

  def Suffix
    Peg::Seq.new(
      Peg::Apply.new(self, :Primary),
      Peg::Maybe.new(
        Peg::Choice.new(
          Peg::Apply.new(self, :QUERY),
          Peg::Apply.new(self, :STAR),
          Peg::Apply.new(self, :PLUS)
        )
      )
    )
  end

  def Primary
    Peg::Choice.new(
      Peg::Apply.new(self, :Primary_identifier),
      Peg::Apply.new(self, :Primary_group),
      Peg::Apply.new(self, :Literal),
      Peg::Apply.new(self, :Class),
      Peg::Apply.new(self, :DOT)
    )
  end

  def Primary_identifier
    Peg::Seq.new(
      Peg::Apply.new(self, :Identifier),
      Peg::Not.new(
        Peg::Apply.new(self, :LEFTARROW)
      )
    )
  end

  def Primary_group
    Peg::Seq.new(
      Peg::Apply.new(self, :OPEN),
      Peg::Apply.new(self, :Expression),
      Peg::Apply.new(self, :CLOSE)
    )
  end

  def Identifier
    Peg::Seq.new(
      Peg::Apply.new(self, :IdentStart),
      Peg::ZeroOrMore.new(
        Peg::Apply.new(self, :IdentCont)
      ),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def IdentStart
    Peg::CharSet.new("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
  end

  def IdentCont
    Peg::Choice.new(
      Peg::Apply.new(self, :IdentStart),
      Peg::CharSet.new("0123456789")
    )
  end

  def Literal
    Peg::Choice.new(
      Peg::Seq.new(
        Peg::Term.new("'"),
        Peg::ZeroOrMore.new(
          Peg::Seq.new(
            Peg::Not.new(
              Peg::Term.new("'")
            ),
            Peg::Apply.new(self, :Char)
          )
        ),
        Peg::Term.new("'"),
        Peg::Apply.new(self, :Spacing)
      ),
      Peg::Seq.new(
        Peg::Term.new('"'),
        Peg::ZeroOrMore.new(
          Peg::Seq.new(
            Peg::Not.new(
              Peg::Term.new('"')
            ),
            Peg::Apply.new(self, :Char)
          )
        ),
        Peg::Term.new('"'),
        Peg::Apply.new(self, :Spacing)
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
          Peg::Apply.new(self, :Range)
        )
      ),
      Peg::Term.new("]"),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def Range
    Peg::Choice.new(
      Peg::Apply.new(self, :Range_multiple),
      Peg::Apply.new(self, :Char)
    )
  end

  def Range_multiple
    Peg::Seq.new(
      Peg::Apply.new(self, :Char),
      Peg::Term.new("-"),
      Peg::Apply.new(self, :Char)
    )
  end

  def Char
    Peg::Choice.new(
      Peg::Apply.new(self, :Char_backslash),
      Peg::Apply.new(self, :Char_doubleQuote),
      Peg::Apply.new(self, :Char_singleQuote),
      Peg::Apply.new(self, :Char_openSquare),
      Peg::Apply.new(self, :Char_closeSquare),
      Peg::Apply.new(self, :Char_backspace),
      Peg::Apply.new(self, :Char_newline),
      Peg::Apply.new(self, :Char_carriageReturn),
      Peg::Apply.new(self, :Char_tab),
      Peg::Apply.new(self, :Char_unicode),
      Peg::Apply.new(self, :Char_hex),
      Peg::Apply.new(self, :Char_regular)
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
      Peg::Apply.new(self, :Hex),
      Peg::Apply.new(self, :Hex),
      Peg::Apply.new(self, :Hex),
      Peg::Apply.new(self, :Hex)
    )
  end

  def Char_hex
    Peg::Seq.new(
      Peg::Term.new("\\x"),
      Peg::Apply.new(self, :Hex),
      Peg::Apply.new(self, :Hex)
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
      Peg::Apply.new(self, :Spacing)
    )
  end

  def SLASH
    Peg::Seq.new(
      Peg::Term.new("/"),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def AND
    Peg::Seq.new(
      Peg::Term.new("&"),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def NOT
    Peg::Seq.new(
      Peg::Term.new("!"),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def QUERY
    Peg::Seq.new(
      Peg::Term.new("?"),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def STAR
    Peg::Seq.new(
      Peg::Term.new("*"),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def PLUS
    Peg::Seq.new(
      Peg::Term.new("+"),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def OPEN
    Peg::Seq.new(
      Peg::Term.new("("),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def CLOSE
    Peg::Seq.new(
      Peg::Term.new(")"),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def DOT
    Peg::Seq.new(
      Peg::Term.new("."),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def DASHES
    Peg::Seq.new(
      Peg::Term.new('--'),
      Peg::Apply.new(self, :Spacing)
    )
  end

  def Spacing
    Peg::ZeroOrMore.new(
      Peg::Choice.new(
        Peg::Apply.new(self, :Space),
        Peg::Apply.new(self, :Comment)
      )
    )
  end

  def Comment
    Peg::Seq.new(
      Peg::Term.new("#"),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Not.new(
            Peg::Apply.new(self, :EndOfLine)
          ),
          Peg::Any.new
        )
      ),
      Peg::Apply.new(self, :EndOfLine)
    )
  end

  def Space
    Peg::Choice.new(
      Peg::Term.new(" "),
      Peg::Term.new("\t"),
      Peg::Apply.new(self, :EndOfLine)
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

Peg::META_GRAMMAR = <<-'END'
Grammar         <- Spacing Definition+ EndOfFile

Definition      <- Identifier LEFTARROW InlineRules
InlineRules     <- NamedSequence ( SLASH NamedSequence )*
Expression      <- Sequence ( SLASH Sequence )*
NamedSequence   <- Sequence ( DASHES Identifier )?
Sequence        <- Prefix*
Prefix          <- ( AND / NOT )? Suffix
Suffix          <- Primary ( QUERY / STAR / PLUS )?
Primary         <- Identifier !LEFTARROW -- identifier
                 / OPEN Expression CLOSE -- group
                 / Literal
                 / Class
                 / DOT

Identifier      <- IdentStart IdentCont* Spacing
IdentStart      <- [a-zA-Z_]
IdentCont       <- IdentStart / [0-9]
Literal         <- ['] ( !['] Char  )* ['] Spacing
                 / ["] ( !["] Char  )* ["] Spacing
Class           <- '[' ( !']' Range )* ']' Spacing
Range           <- Char '-' Char -- multiple
                 / Char

Char            <- '\\\\'                -- backslash
                 / '\\\"'                -- doubleQuote
                 / '\\\''                -- singleQuote
                 / '\\['                 -- openSquare
                 / '\\]'                 -- closeSquare
                 / '\\b'                 -- backspace
                 / '\\n'                 -- newline
                 / '\\r'                 -- carriageReturn
                 / '\\t'                 -- tab
                 / '\\u' Hex Hex Hex Hex -- unicode
                 / '\\x' Hex Hex         -- hex
                 / !'\\' .               -- regular

Hex             <- [0-9a-fA-F]
LEFTARROW       <- '<-' Spacing
SLASH           <- '/' Spacing
AND             <- '&' Spacing
NOT             <- '!' Spacing
QUERY           <- '?' Spacing
STAR            <- '*' Spacing
PLUS            <- '+' Spacing
OPEN            <- '(' Spacing
CLOSE           <- ')' Spacing
DOT             <- '.' Spacing
DASHES          <- '--' Spacing
Spacing         <- ( Space / Comment )*
Comment         <- '#' ( !EndOfLine . )* EndOfLine
Space           <- ' ' / '\t' / EndOfLine
EndOfLine       <- '\r\n' / '\n' / '\r'
EndOfFile       <- !.
END
