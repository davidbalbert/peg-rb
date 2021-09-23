class Peg::Parser < Peg
  def root
    Peg::Apply.new(self, :Grammar)
  end

  def Grammar
    Peg::Seq.new(
      Peg::Apply.new(self, :Spacing),
      Peg::OneOrMore.new(Peg::Apply.new(self, :Definition)),
      Peg::Apply.new(self, :EndOfFile),
    )
  end

  def Definition
    Peg::Seq.new(
      Peg::Apply.new(self, :Identifier),
      Peg::Apply.new(self, :LEFTARROW),
      Peg::Apply.new(self, :Expression),
    )
  end

  def Expression
    Peg::Seq.new(
      Peg::Apply.new(self, :Sequence),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Apply.new(self, :SLASH),
          Peg::Apply.new(self, :Sequence),
        ),
      ),
    )
  end

  def Sequence
    Peg::ZeroOrMore.new(Peg::Apply.new(self, :Prefix))
  end

  def Prefix
    Peg::Seq.new(
      Peg::Maybe.new(Peg::Choice.new(Peg::Apply.new(self, :AND), Peg::Apply.new(self, :NOT))),
      Peg::Apply.new(self, :Suffix),
    )
  end

  def Suffix
    Peg::Seq.new(
      Peg::Apply.new(self, :Primary),
      Peg::Maybe.new(
        Peg::Choice.new(
          Peg::Apply.new(self, :QUERY),
          Peg::Apply.new(self, :STAR),
          Peg::Apply.new(self, :PLUS),
        ),
      ),
    )
  end

  def Primary
    Peg::Choice.new(
      Peg::Seq.new(
        Peg::Apply.new(self, :Identifier),
        Peg::Not.new(Peg::Apply.new(self, :LEFTARROW))
      ),
      Peg::Seq.new(Peg::Apply.new(self, :OPEN), Peg::Apply.new(self, :Expression), Peg::Apply.new(self, :CLOSE)),
      Peg::Apply.new(self, :Literal),
      Peg::Apply.new(self, :Class),
      Peg::Apply.new(self, :DOT),
    )
  end

  def Identifier
    Peg::Seq.new(
      Peg::Apply.new(self, :IdentStart),
      Peg::ZeroOrMore.new(Peg::Apply.new(self, :IdentCont)),
      Peg::Apply.new(self, :Spacing),
    )
  end

  def IdentStart
    Peg::CharSet.new("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
  end

  def IdentCont
    Peg::Choice.new(Peg::Apply.new(self, :IdentStart), Peg::CharSet.new("0123456789"))
  end

  def Literal
    Peg::Choice.new(
      Peg::Seq.new(
        Peg::Term.new("'"),
        Peg::ZeroOrMore.new(
          Peg::Seq.new(Peg::Not.new(Peg::Term.new("'")), Peg::Apply.new(self, :Char))
        ),
        Peg::Term.new("'"),
        Peg::Apply.new(self, :Spacing),
      ),
      Peg::Seq.new(
        Peg::Term.new('"'),
        Peg::ZeroOrMore.new(
          Peg::Seq.new(Peg::Not.new(Peg::Term.new('"')), Peg::Apply.new(self, :Char))
        ),
        Peg::Term.new('"'),
        Peg::Apply.new(self, :Spacing),
      ),
    )
  end

  def Class
    Peg::Seq.new(
      Peg::Term.new("["),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(Peg::Not.new(Peg::Term.new("]")), Peg::Apply.new(self, :Range))
      ),
      Peg::Term.new("]"),
      Peg::Apply.new(self, :Spacing),
    )
  end

  def Range
    Peg::Choice.new(
      Peg::Seq.new(self.Char, Peg::Term.new("-"), Peg::Apply.new(self, :Char)),
      Peg::Apply.new(self, :Char),
    )
  end

  def Char
    Peg::Choice.new(
      Peg::Seq.new(Peg::Term.new("\\"), Peg::CharSet.new("abefnrtv'\"[]\\")),
      Peg::Seq.new(Peg::Term.new("\\"), Peg::CharSet.new("0123"), Peg::CharSet.new("01234567"), Peg::CharSet.new("01234567")),
      Peg::Seq.new(Peg::Term.new("\\"), Peg::CharSet.new("01234567"), Peg::Maybe.new(Peg::CharSet.new("01234567"))),
      Peg::Term.new("\\-"),
      Peg::Seq.new(Peg::Not.new(Peg::Term.new("\\")), Peg::Any.new),
    )
  end

  def LEFTARROW
    Peg::Seq.new(Peg::Term.new("<-"), Peg::Apply.new(self, :Spacing))
  end

  def SLASH
    Peg::Seq.new(Peg::Term.new("/"), Peg::Apply.new(self, :Spacing))
  end

  def AND
    Peg::Seq.new(Peg::Term.new("&"), Peg::Apply.new(self, :Spacing))
  end

  def NOT
    Peg::Seq.new(Peg::Term.new("!"), Peg::Apply.new(self, :Spacing))
  end

  def QUERY
    Peg::Seq.new(Peg::Term.new("?"), Peg::Apply.new(self, :Spacing))
  end

  def STAR
    Peg::Seq.new(Peg::Term.new("*"), Peg::Apply.new(self, :Spacing))
  end

  def PLUS
    Peg::Seq.new(Peg::Term.new("+"), Peg::Apply.new(self, :Spacing))
  end

  def OPEN
    Peg::Seq.new(Peg::Term.new("("), Peg::Apply.new(self, :Spacing))
  end

  def CLOSE
    Peg::Seq.new(Peg::Term.new(")"), Peg::Apply.new(self, :Spacing))
  end

  def DOT
    Peg::Seq.new(Peg::Term.new("."), Peg::Apply.new(self, :Spacing))
  end

  def Spacing
    Peg::ZeroOrMore.new(
      Peg::Choice.new(
        Peg::Apply.new(self, :Space),
        Peg::Apply.new(self, :Comment),
      ),
    )
  end

  def Comment
    Peg::Seq.new(
      Peg::Term.new("#"),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Not.new(Peg::Apply.new(self, :EndOfLine)),
          Peg::Any.new,
        ),
      ),
      Peg::Apply.new(self, :EndOfLine),
    )
  end

  def Space
    Peg::Choice.new(
      Peg::Term.new(" "),
      Peg::Term.new("\t"),
      Peg::Apply.new(self, :EndOfLine),
    )
  end

  def EndOfLine
    Peg::Choice.new(
      Peg::Term.new("\r\n"),
      Peg::Term.new("\n"),
      Peg::Term.new("\r"),
    )
  end

  def EndOfFile
    Peg::Not.new(Peg::Any.new)
  end
end

Peg::META_GRAMMAR = <<~END
Grammar         <- Spacing Definition+ EndOfFile

Definition      <- Identifier LEFTARROW Expression
Expression      <- Sequence ( SLASH Sequence )*
Sequence        <- Prefix*
Prefix          <- ( AND / NOT )? Suffix
Suffix          <- Primary ( QUERY / STAR / PLUS )?
Primary         <- Identifier !LEFTARROW
                 / OPEN Expression CLOSE
                 / Literal
                 / Class
                 / DOT

Identifier      <- IdentStart IdentCont* Spacing
IdentStart      <- [a-zA-Z_]
IdentCont       <- IdentStart / [0-9]
Literal         <- ['] ( !['] Char  )* ['] Spacing
                 / ["] ( !["] Char  )* ["] Spacing
Class           <- '[' ( !']' Range )* ']' Spacing
Range           <- Char '-' Char / Char
Char            <- '\\\\' [abefnrtv'"\\[\\]\\\\]
                 / '\\\\' [0-3][0-7][0-7]
                 / '\\\\' [0-7][0-7]?
                 / '\\\\' '-'
                 / !'\\\\' .
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
Spacing         <- ( Space / Comment )*
Comment         <- '#' ( !EndOfLine . )* EndOfLine
Space           <- ' ' / '\t' / EndOfLine
EndOfLine       <- '\r\n' / '\n' / '\r'
EndOfFile       <- !.
END

# Grammar         <- Spacing Definition+ EndOfFile
#
# Definition      <- Identifier LEFTARROW Expression
# Expression      <- Sequence ( SLASH Sequence )*
# Sequence        <- Prefix*
# Prefix          <- ( AND / NOT )? Suffix
# Suffix          <- Primary ( QUERY / STAR / PLUS )?
# Primary         <- Identifier !LEFTARROW
#                  / OPEN Expression CLOSE
#                  / Literal
#                  / Class
#                  / DOT
#
# Identifier      <- IdentStart IdentCont* Spacing
# IdentStart      <- [a-zA-Z_]
# IdentCont       <- IdentStart / [0-9]
# Literal         <- ['] ( !['] Char  )* ['] Spacing
#                  / ["] ( !["] Char  )* ["] Spacing
# Class           <- '[' ( !']' Range )* ']' Spacing
# Range           <- Char '-' Char / Char
# Char            <- '\\' [abefnrtv'"\[\]\\]
#                  / '\\' [0-3][0-7][0-7]
#                  / '\\' [0-7][0-7]?
#                  / '\\' '-'
#                  / !'\\' .
# LEFTARROW       <- '<-' Spacing
# SLASH           <- '/' Spacing
# AND             <- '&' Spacing
# NOT             <- '!' Spacing
# QUERY           <- '?' Spacing
# STAR            <- '*' Spacing
# PLUS            <- '+' Spacing
# OPEN            <- '(' Spacing
# CLOSE           <- ')' Spacing
# DOT             <- '.' Spacing
# Spacing         <- ( Space / Comment )*
# Comment         <- '#' ( !EndOfLine . )* EndOfLine
# Space           <- ' ' / '\t' / EndOfLine
# EndOfLine       <- '\r\n' / '\n' / '\r'
# EndOfFile       <- !.

