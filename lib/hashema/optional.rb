require_relative 'schema'

module Hashema
  Optional = Struct.new(:expected)

  def self.Optional(value)
    Optional.new(value)
  end
end
