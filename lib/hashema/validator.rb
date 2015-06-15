require_relative './compiler'

module Hashema
  class Validator
    def initialize(actual, schema, options={})
      @actual = actual
      @schema = Compiler.compile schema, options
    end

    def valid?
      comparison.match?
    end

    def failure_message
      comparison.mismatches[0].message
    end

    private

    def comparison
      @comparison ||= @schema.compare(@actual)
    end
  end
end
