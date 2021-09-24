class Peg
  class Generator
    def Expression(choice, choices)
      # choices: [('/', String)...]
      Choice.new(choice, *choices.map {|(_, c)| c})
    end

    def Choice(seq, rule_name)
      # rule_name: ('--', String)?
      if rule_name
        rule_name = rule_name[1]
      end

      # TODO: use rule_name

      seq
    end

    def Sequence(prefixes)
      case prefixes.size
      when 0
        Never.new
      when 1
        prefixes[0]
      else
        Seq.new(*prefixes)
      end
    end

    def Prefix(prefix, suffix)
      case prefix
      when "&"
        And.new(suffix)
      when "!"
        Not.new(suffix)
      when nil
        suffix
      else
        raise "Invalid prefix: #{prefix}"
      end
    end

    def Suffix(primary, suffix)
      case suffix
      when "?"
        Maybe.new(primary)
      when "*"
        ZeroOrMore.new(primary)
      when "+"
        OneOrMore.new(primary)
      when nil
        primary
      else
        raise "Invalid suffix: #{suffix}"
      end
    end

    def Primary_identifier(id, _)
      id
    end

    def Primary_group(_, expr, _)
      expr
    end

    def Identifier(start, cont, _)
      start + cont.join
    end

    def Literal(_, chars, _, _)
      # chars: [(nil, String)...]
      Term.new(chars.map {|(_, c)| c }.join)
    end

    def Class(_, ranges, _, _)
      # ranges: [(nil, String)...]
      CharSet.new(ranges.map {|(_, c)| c }.join)
    end

    def Range_multiple(first, _, last)
      (first..last).to_a.join
    end

    def Char_backslash(_)
      "\\"
    end

    def Char_doubleQuote(_)
      '"'
    end

    def Char_singleQuote(_)
      "'"
    end

    def Char_openSquare(_)
      "["
    end

    def Char_closeSquare(_)
      "]"
    end

    def Char_backspace(_)
      "\b"
    end

    def Char_newline(_)
      "\n"
    end

    def Char_carriageReturn(_)
      "\r"
    end

    def Char_tab(_)
      "\t"
    end

    def Char_unicode(_, h1, h2, h3, h4)
      ("0x"+h1+h2+h3+h4).to_i(16).chr(Encoding::UTF_8)
    end

    def Char_hex(_, h1, h2)
      ("0x"+h1+h2).to_i(16).chr
    end

    def Char_regular(_, c)
      c
    end

    def LEFTARROW(arrow, _)
      arrow
    end

    def SLASH(slash, _)
      slash
    end

    def AND(amp, _)
      amp
    end

    def NOT(bang, _)
      bang
    end

    def QUERY(query, _)
      query
    end

    def STAR(star, _)
      star
    end

    def PLUS(plus, _)
      plus
    end

    def OPEN(open, _)
      open
    end

    def CLOSE(close, _)
      close
    end

    def DOT(_, _)
      Any.new
    end

    def DASHES(dashes, _)
      dashes
    end
  end
end
