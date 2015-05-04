require_relative '../lib/hashema/schema'
require_relative './support/look_like'

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

  describe Hash do
    it 'matches a hash with the same keys and values' do
      schema = Hash.new(
        foo: Atom.new(Numeric),
        bar: Atom.new(Numeric)
      )

      comparison = schema.compare(
        foo: 1,
        bar: 2
      )

      expect(comparison).to be_match
    end

    it 'complains about a hash with a different set of keys' do
      schema = Hash.new(
        foo: Atom.new(Numeric),
        bar: Atom.new(Numeric)
      )

      mismatches = schema.compare(
        foo: 1,
        bar: 2,
        baz: 3
      ).mismatches

      expect(mismatches.size).to eq 1

      expect(mismatches[0].actual).to eq(foo: 1, bar: 2, baz: 3)
      expect(mismatches[0].expected).to be_a ::Hash
      expect(mismatches[0].location).to eq []
    end

    it 'complains about a non-hash value' do
      schema = Hash.new(foo: Atom.new(Numeric))

      mismatches = schema.compare('squirrel').mismatches

      expect(mismatches.size).to eq 1

      expect(mismatches[0].actual).to eq 'squirrel'
      expect(mismatches[0].expected).to eq ::Hash
      expect(mismatches[0].location).to eq []
    end

    it 'complains about a hash with a non-matching value' do
      schema = Hash.new(
        foo: Atom.new(Numeric),
        bar: Atom.new(Numeric)
      )

      mismatches = schema.compare(
        foo: 1,
        bar: 'squirrel'
      ).mismatches

      expect(mismatches.size).to eq 1

      expect(mismatches[0].actual).to eq 'squirrel'
      expect(mismatches[0].expected).to eq Numeric
      expect(mismatches[0].location).to eq [:bar]
    end

    it 'pinpoints mismatches within nested structures' do
      schema = Hash.new(
        foo: Array.new(
          Hash.new(
            bar: Atom.new(Numeric)
          )
        )
      )

      mismatches = schema.compare(
        foo: [
          {bar: 1},
          {bar: 'squirrel'},
          {bar: 3},
          {asdf: 1},
        ]
      ).mismatches

      expect(mismatches.size).to eq 2

      expect(mismatches[0].actual).to eq 'squirrel'
      expect(mismatches[0].expected).to eq Numeric
      expect(mismatches[0].location).to eq [:foo, 1, :bar]

      expect(mismatches[1].message).to include 'have a different set of keys'
    end
  end

  describe Alternatives do
    it 'matches a value that matches any of the alternatives' do
      schema = Alternatives.new(
        Atom.new('ok'),
        Atom.new('awful'),
        Atom.new(1..5)
      )

      expect(schema.compare(3)).to be_match
      expect(schema.compare('ok')).to be_match
      expect(schema.compare('awful')).to be_match
    end

    it 'does not match a value that matches none of the alternatives' do
      schema = Alternatives.new(
        Atom.new('ok'),
        Atom.new('awful'),
        Atom.new(1..5)
      )

      expect(schema.compare(-1)).not_to be_match
      expect(schema.compare('bork')).not_to be_match
      expect(schema.compare(nil)).not_to be_match
    end
  end

  describe HashWithIndifferentAccess do
    let(:schema) do
      Hashema::HashWithIndifferentAccess.new(
        foo: Atom.new(1),
        'bar' => Atom.new(2),
        'baz' => Atom.new(3),
        kludge: Atom.new(4)
      )
    end

    it 'matches a hash whose keys convert to the same strings' do
      match = {foo: 1, bar: 2, 'baz' => 3, 'kludge' => 4}
      expect(schema.compare(match)).to be_match
    end

    it 'complains about a hash with extra keys' do
      extra_keys = {foo: 1, bar: 2, 'baz' => 3, 'kludge' => 4, extra: 5}
      comparison = schema.compare(extra_keys)
      expect(comparison).not_to be_match
      expect(comparison.mismatches[0].message).to look_like %q(
        expected / to have a different set of keys
        extra keys were:
        :extra
      )
    end

    it 'complains about a hash with missing keys' do
      missing_keys = {foo: 1, bar: 2, 'baz' => 3}
      comparison = schema.compare(missing_keys)
      expect(comparison).not_to be_match
      expect(comparison.mismatches[0].message).to look_like %q(
        expected / to have a different set of keys
        missing keys were:
        :kludge
      )
    end

    it 'does not match if any value does not match' do
      mismatch = {foo: 1, bar: 2, 'baz' => 3, 'kludge' => :mismatch}
      comparison = schema.compare(mismatch)
      expect(comparison).not_to be_match
      expect(comparison.mismatches[0].message).to look_like %q(
        expected /kludge to match 4 but got :mismatch
      )
    end
  end
end
