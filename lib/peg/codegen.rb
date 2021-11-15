module Peg
  using Indentation

  class Grammar
    def self.to_rb(class_name=name)
      new.to_rb(class_name)
    end

    def to_rb(class_name)
      <<~RUBY
        class #{class_name} < Peg::Grammar
          self.default_rule = :#{self.class.default_rule}

        #{
          self.class.rules.map do |name|
            body = send(name)

            <<~METHOD.indent(2)
              def #{name}
              #{body.to_rb.indent(2)}
              end
            METHOD
          end.join("\n\n")
        }
        end
      RUBY
    end
  end

  class Term
    def to_rb
      <<~RUBY
        Peg::Term.new(#{value.inspect})
      RUBY
    end
  end

  class Seq
    def to_rb
      <<~RUBY
        Peg::Seq.new(
        #{exprs.map {|e| e.to_rb.indent(2)}.join(",\n")}
        )
      RUBY
    end
  end

  class Choice
    def to_rb
      <<~RUBY
        Peg::Choice.new(
        #{options.map {|e| e.to_rb.indent(2)}.join(",\n")}
        )
      RUBY
    end
  end

  class CharSet
    def to_rb
      <<~RUBY
        Peg::CharSet.new(#{chars.inspect})
      RUBY
    end
  end

  class ZeroOrMore
    def to_rb
      <<~RUBY
        Peg::ZeroOrMore.new(
        #{expr.to_rb.indent(2)}
        )
      RUBY
    end
  end

  class OneOrMore
    def to_rb
      <<~RUBY
        Peg::OneOrMore.new(
        #{expr.to_rb.indent(2)}
        )
      RUBY
    end
  end

  class Maybe
    def to_rb
      <<~RUBY
        Peg::Maybe.new(
        #{expr.to_rb.indent(2)}
        )
      RUBY
    end
  end

  class Any
    def to_rb
      <<~RUBY
        Peg::Any.new
      RUBY
    end
  end

  class Never
    def to_rb
      <<~RUBY
        Peg::Never.new
      RUBY
    end
  end

  class And
    def to_rb
      <<~RUBY
        Peg::And.new(
        #{expr.to_rb.indent(2)}
        )
      RUBY
    end
  end

  class Not
    def to_rb
      <<~RUBY
        Peg::Not.new(
        #{expr.to_rb.indent(2)}
        )
      RUBY
    end
  end

  class Apply
    def to_rb
      <<~RUBY
        Peg::Apply.new(:#{rule})
      RUBY
    end
  end
end
