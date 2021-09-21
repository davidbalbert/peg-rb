# Grammar         <- Spacing Definition+ EndOfFile
#
# Definition      <- Identifier LEFTARROW Expression
# Expression      <- Sequence ( SLASH Sequence )*
# Sequence        <- Prefix*
# Prefix          <- ( AND | NOT )? Suffix
# Suffix          <- Primary ( QUERY / STAR / PLUS )?
# Primary         <- Identifier !LEFTARROW
#                  / OPEN Expression CLOSE
#                  / Literal
#                  / Class
#                  / DOT
#
# Identifier      <- < IdentStart IdentCont* > Spacing
# IdentStart      <- [a-zA-Z_]
# IdentCont       <- IdentStart / [0-9]
# Literal         <- ['] < ( !['] Char  )* > ['] Spacing
#                  / ["] < ( !["] Char  )* > ["] Spacing
# Class           <- '[' < ( !']' Range )* > ']' Spacing
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


class Peg::Parser < Peg
  def Char
    Peg::Choice.new(
      Peg::Seq.new(Peg::Term.new("\\"), Peg::CharSet.new("abefnrtv'\"[]\\")),
      # ...
    )
  end

  def LEFTARROW
    Peg::Seq.new(Peg::Term.new("<-"), Spacing)
  end

  def SLASH
    Peg::Seq.new(Peg::Term.new("/"), Spacing)
  end

  def AND
    Peg::Seq.new(Peg::Term.new("&"), Spacing)
  end

  def NOT
    Peg::Seq.new(Peg::Term.new("!"), Spacing)
  end

  def QUERY
    Peg::Seq.new(Peg::Term.new("?"), Spacing)
  end

  def STAR
    Peg::Seq.new(Peg::Term.new("*"), Spacing)
  end

  def PLUS
    Peg::Seq.new(Peg::Term.new("+"), Spacing)
  end

  def OPEN
    Peg::Seq.new(Peg::Term.new("("), Spacing)
  end

  def CLOSE
    Peg::Seq.new(Peg::Term.new(")"), Spacing)
  end

  def DOT
    Peg::Seq.new(Peg::Term.new("."), Spacing)
  end

  def Spacing
    Peg::ZeroOrMore.new(Peg::Choice.new(Space, Comment))
  end

  def Comment
    Peg::Seq.new(
      Peg::Term("#"),
      Peg::ZeroOrMore.new(
        Peg::Seq.new(
          Peg::Not.new(EndOfLine),
          Peg::Any.new,
        ),
      ),
      EndOfLine,
    )
  end

  def Space
    Peg::Choice.new(
      Peg::Term.new(" "),
      Peg::Term.new("\t"),
      EndOfLine,
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
