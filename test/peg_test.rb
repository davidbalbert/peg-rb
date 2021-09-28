require "test_helper"

# words <- (word space)* word
# word  <- [a-z]+
# space  <- (" " / "\t")+

class Words < Peg::Grammar
  def root
    Peg::Apply.new(self, :words)
  end

  def words
    Peg::Seq.new(
      Peg::ZeroOrMore.new(Peg::Seq.new(Peg::Apply.new(self, :word), Peg::Apply.new(self, :space))),
      Peg::Apply.new(self, :word)
    )
  end

  def word
    Peg::OneOrMore.new(Peg::CharSet.new("abcdefghijklmnopqrstuvwxyz"))
  end

  def space
    Peg::OneOrMore.new(Peg::Choice.new(Peg::Term.new(" "), Peg::Term.new("\t")))
  end
end

class WordsTest < Test
  test "success" do
    words = Words.new
    assert_equal true, words.match?("foo")
    assert_equal true, words.match?("foo bar")
    assert_equal true, words.match?("foo    bar\t baz")
  end

  test "failure" do
    words = Words.new
    assert_equal false, words.match?("42")
    assert_equal false, words.match?("    ")
    assert_equal false, words.match?("")
  end
end

# root            <- space* expr space* eof
# expr            <- (number plus)* number
# plus            <- "+" space*
# number          <- ("-" space*)? positive_number
# positive_number <- [0-9]+ space*
# space           <- " " / "\t"
# eof             <- !.

class Calc < Peg::Grammar
  def root
    Peg::Seq.new(
      Peg::ZeroOrMore.new(Peg::Apply.new(self, :space)),
      Peg::Apply.new(self, :expr),
      Peg::ZeroOrMore.new(Peg::Apply.new(self, :space)),
      Peg::Apply.new(self, :eof),
    )
  end

  def expr
    Peg::Seq.new(
      Peg::ZeroOrMore.new(Peg::Seq.new(Peg::Apply.new(self, :number), Peg::Apply.new(self, :plus))),
      Peg::Apply.new(self, :number)
    )
  end

  def plus
    Peg::Seq.new(Peg::Term.new("+"), Peg::ZeroOrMore.new(Peg::Apply.new(self, :space)))
  end

  def number
    Peg::Seq.new(
      Peg::Maybe.new(
        Peg::Seq.new(
          Peg::Term.new("-"),
          Peg::ZeroOrMore.new(Peg::Apply.new(self, :space)),
        )
      ),
      Peg::Apply.new(self, :positive_number),
    )
  end

  def positive_number
    Peg::Seq.new(
      Peg::OneOrMore.new(
        Peg::Choice.new(*%w(0 1 2 3 4 5 6 7 8 9).map { |s| Peg::Term.new(s) })
      ),
      Peg::ZeroOrMore.new(Peg::Apply.new(self, :space))
    )
  end

  def space
    Peg::Choice.new(Peg::Term.new(" "), Peg::Term.new("\t"))
  end

  def eof
    Peg::Not.new(Peg::Any.new)
  end
end

class CalcTest < Test
  test "numbers" do
    calc = Calc.new
    assert_equal true, calc.match?("42")
    assert_equal true, calc.match?("-42")
    assert_equal true, calc.match?("- 42")
    assert_equal false, calc.match?("hello")
    assert_equal false, calc.match?("-42 hello")
  end

  test "addition" do
    calc = Calc.new
    assert_equal true, calc.match?("1+2")
    assert_equal true, calc.match?("1 +   2 + 3+4")
    assert_equal true, calc.match?("1\t+\t2")
  end
end

# root <- "foo" &" bar"

class And < Peg::Grammar
  def root
    Peg::Seq.new(
      Peg::Term.new("foo"),
      Peg::And.new(Peg::Term.new(" bar"))
    )
  end
end

class AndTest < Test
  test "and" do
    a = And.new
    assert_equal false, a.match?("foo")
    assert_equal false, a.match?("foo b")
    assert_equal true,  a.match?("foo bar")
    assert_equal 3,     a.parse("foo bar")&.nchars
  end
end
