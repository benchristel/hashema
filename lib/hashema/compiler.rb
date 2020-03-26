require_relative './schema'

module Hashema
  class Compiler
    def self.compile(thing, options={})
      new(options).compile(thing)
    end

    def initialize(options={})
      @options = options
    end

    def compile(thing)
      case thing
      when Hashema::Optional
        Hashema::OptionalValueInHash.new(compile(thing.expected))
      when ::Array
        if thing.size == 1
          Hashema::Array.new(compile(thing[0]))
        else
          Hashema::Alternatives.new(*(thing.map { |element| compile element }))
        end
      when ::Hash
        compile_hash(thing)
      else
        Hashema::Atom.new(thing)
      end
    end

    private

    def compile_hash(hash)
      with_compiled_values = ::Hash[hash.map { |k, v| [k, compile(v)]}]
      klass = @options[:indifferent_access] ?
        Hashema::HashWithIndifferentAccess :
        Hashema::Hash
      klass.new(with_compiled_values)
    end
  end
end
