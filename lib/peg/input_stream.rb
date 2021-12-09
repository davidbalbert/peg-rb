module Peg
  class Slice
    attr_reader :source, :range

    def initialize(source, range)
      @source = source
      @range = range
    end

    def contents
      @contents ||= source[range]
    end

    def inspect
      "#<Peg::Slice @range=#{range.inspect}>"
    end
  end

  class InputStream
    attr_reader :pos

    def initialize(s)
      @s = s
      @pos = 0
    end

    def reset(pos)
      @pos = pos
    end

    def getc
      c = @s[@pos]
      @pos += 1 unless c.nil?

      c
    end

    def empty?
      @pos == @s.size
    end

    def size
      @s.size - @pos
    end

    def [](range)
      Slice.new(@s, range)
    end

    def slice_to_current(start)
      self[start...@pos]
    end

    def until_next_newline
      @s[@pos..@s.index("\n", @pos)].chomp
    end

    def start_with?(value)
      value.chars.each do |c|
        if c != getc
          return false
        end
      end

      true
    end
  end
end
