require_relative '../lib/hashema/schema'

module Hashema
  describe Atom do
    it 'matches an equal value' do
      expect(Atom.new(1).compare(1).match?).to be true
    end

    it 'matches a member of a set' do
      expect(Atom.new(1..3).compare(2).match?).to be true
    end

    it 'complains about an unequal value' do
      expect(Atom.new(1).compare(2).match?).to be false
      expect(Atom.new(1).compare(2).actual).to eq 2
      expect(Atom.new(1).compare(2).expected).to eq 1
    end
  end

  describe Array do
    it 'matches an array if all its items match' do
      schema = Array.new(Atom.new(String))
      expect(schema.compare(['dog', 'cat', 'horse']).match?).to be true
    end

    it 'does not match if any item does not match' do
      schema = Array.new(Atom.new(String))
      expect(schema.compare(['dog', 'cat', 333]).match?).to be false
    end

    it 'complains about the type of a non-array value' do
      schema = Array.new(Atom.new(String))
      comparison = schema.compare('foo')
      expect(comparison.match?).to be false
      expect(comparison.mismatches[0].actual).to eq 'foo'
      expect(comparison.mismatches[0].expected).to eq ::Array
      expect(comparison.mismatches[0].location).to eq []
    end

    it 'pinpoints the mismatches in an array value' do
      schema = Array.new(Atom.new(String))
      comparison = schema.compare(['dog', 'cat', 333, 444])

      mismatches = comparison.mismatches
      expect(mismatches.size).to eq 2
      expect(mismatches[0].expected).to eq String
      expect(mismatches[0].actual).to eq 333
      expect(mismatches[0].location).to eq [2]
      expect(mismatches[1].expected).to eq String
      expect(mismatches[1].actual).to eq 444
      expect(mismatches[1].location).to eq [3]
    end

    it 'pinpoints the mismatches in a nested structure' do
      schema = Array.new(Array.new(Atom.new(Numeric)))
      comparison = schema.compare([
        [1,2],
        [3,4,5,'squirrel','rat'],
        [7,'bear'],
        'not an array'
      ])

      mismatches = comparison.mismatches
      expect(mismatches.size).to eq 4

      expect(mismatches[0].actual).to eq 'squirrel'
      expect(mismatches[0].expected).to eq Numeric
      expect(mismatches[0].location).to eq [1, 3]

      expect(mismatches[1].actual).to eq 'rat'
      expect(mismatches[1].expected).to eq Numeric
      expect(mismatches[1].location).to eq [1, 4]

      expect(mismatches[2].actual).to eq 'bear'
      expect(mismatches[2].expected).to eq Numeric
      expect(mismatches[2].location).to eq [2, 1]

      expect(mismatches[3].actual).to eq 'not an array'
      expect(mismatches[3].expected).to eq ::Array
      expect(mismatches[3].location).to eq [3]
    end
  end
end
