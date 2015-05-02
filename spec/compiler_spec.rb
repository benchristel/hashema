require_relative '../lib/hashema/compiler'

module Hashema
  describe Compiler do
    it 'compiles a value into an Atom' do
      expect(Compiler.compile(String)).to eq Atom.new(String)
    end

    it 'compiles an array of one element into a Hashema::Array' do
      expect(Compiler.compile([String])).to eq Hashema::Array.new(Atom.new(String))
    end

    it 'compiles an array of multiple elements into Alternatives' do
      expect(Compiler.compile([true, false])).to eq Hashema::Alternatives.new(Atom.new(true), Atom.new(false))
    end

    it 'compiles a hash into a Hashema::Hash' do
      expect(Compiler.compile({foo: [String], bar: [{baz: Numeric}]})).to eq(
        Hash.new(
          foo: Array.new(Atom.new(String)),
          bar: Array.new(
            Hash.new(
              baz: Atom.new(Numeric)
            )
          )
        )
      )
    end

    context 'opting for indifferent_access: true' do
      it 'compiles a hash into a Hashema::HashWithIndifferentAccess' do
        compiled = Compiler.compile({foo: 1}, indifferent_access: true)
        expect(compiled).to be_a Hashema::HashWithIndifferentAccess
      end
    end
  end
end
