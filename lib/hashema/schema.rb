module Hashema
  class Schema < Struct.new(:ideal)
    def compare(real)
      self.class.const_get('Comparison').new(real, ideal)
    end
  end

  class Comparison < Struct.new(:actual, :expected)
    def match?
      @match ||= perform
    end

    def mismatch_actual
      match?
      @mismatch_actual
    end

    def mismatch_expected
      match?
      @mismatch_expected
    end

    def mismatch_location
      match?
      @mismatch_location
    end
  end

  class Atom < Schema
    class Comparison < Hashema::Comparison
      def perform
        @mismatches = []
        if expected === actual
          true
        else
          @mismatches << Mismatch.new(actual, expected, [])
          false
        end
      end

      def mismatches
        @mismatches = []
        match?
        @mismatches
      end
    end
  end

  class Array < Schema
    class Comparison < Hashema::Comparison
      def perform
        types_match? and elements_match?

      end

      def types_match?
        if actual.is_a? ::Array
          true
        else
          @mismatches = [Mismatch.new(actual, ::Array, [])]
          false
        end
      end

      def elements_match?
        @mismatches = []
        actual.each_with_index.map do |actual, i|

          comparison = expected.compare(actual)

          if comparison.match?
            true
          else
            @mismatch_location = [i]
            @mismatch_actual = comparison.mismatches[0].actual
            @mismatch_expected = comparison.mismatches[0].expected
            @mismatch_location = [i] + comparison.mismatches[0].location
            @mismatches << Mismatch.new(@mismatch_actual, @mismatch_expected, @mismatch_location)
            false
          end
        end.all?
      end

      def mismatches
        @mismatches = []
        match?
        @mismatches
      end
    end
  end

  class Mismatch < Struct.new(:actual, :expected, :location)
  end
end
