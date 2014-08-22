require_relative '../lib/hashema'

describe Hashema::Validator do
  describe '#valid?' do
    it "returns true when the object and schema match" do
      object = {
        foo: [
          { bar: 1 },
          { bar: 2 }
        ]
      }

      schema = {
        foo: [{bar: Numeric}]
      }

      expect( described_class.new(object, schema).valid? ).to be true
    end

    it "returns false when the object and schema don't match" do
      object = {
        foo: [
          { bar: 1 },
          { bar: 'squirrel' }
        ]
      }

      schema = {
        foo: [{bar: Numeric}]
      }

      expect( described_class.new(object, schema).valid? ).to be false
    end
  end

  describe '#failure_message' do
    let :validator do
      validator = described_class.new(object, schema)
    end

    let :object do
      { foo:
        [ { bar: 1 },
          { bar: 'squirrel' }
        ]
      }
    end

    let :schema do
      {foo: [{bar: Numeric}]}
    end

    let(:message) { validator.failure_message.gsub(/\s+/,' ') }

    it 'includes the path to the point where the mismatch occurred' do
      expect(message).to include '/foo/1/bar'
    end

    it 'pinpoints the reason for the mismatch' do
      expect(message).to include 'to match Numeric but got "squirrel"'
    end

    context "when the mismatch involves a set of alternatives" do
      let :object do
        { foo: [
            { bar: 123 },
            { bar: '123' },
            { bar: 'squirrel' }
          ]
        }
      end

      let :schema do
        { foo: [
            { bar: [Numeric, /\d+/] }
          ]
        }
      end

      it 'includes all the alternatives in the message' do
        expect(message).to include 'to match [Numeric, /\d+/] but got "squirrel"'
      end
    end

    context "when {} is compared with []" do
      let(:object) { [] }
      let(:schema) { {} }

      it 'provides a descriptive failure message' do
        expect(message).to include 'expected / to be a Hash, but got Array'
      end
    end

    context "when [] is compared with {}" do
      let(:object) { {} }
      let(:schema) { [:squirrel] }

      it 'provides a descriptive failure message' do
        expect(message).to include 'expected / to be an Array, but got Hash'
      end
    end

    context "when a validated hash has too many keys" do
      let(:object) { {foo: 1, bar: 2, baz: 3} }
      let(:schema) { {foo: Numeric} }

      it 'provides a descriptive failure message' do
        expect(message).to include 'expected / to have a different set of keys'
        expect(message).to include 'extra keys were: :bar :baz'
        expect(message).not_to include 'missing keys'
      end
    end

    context "when a validated hash has too few keys" do
      let(:object) { {foo: 1} }
      let(:schema) { {foo: Numeric, bar: Numeric, baz: Numeric} }

      it 'provides a descriptive failure message' do
        expect(message).to include 'expected / to have a different set of keys'
        expect(message).to include 'missing keys were: :bar :baz'
        expect(message).not_to include 'extra keys'
      end
    end

    context "when the schema includes a set of alternatives and there is a different problem at the same level" do
      let :object do
        { users:
          [
            { name: 'bob',
              site: {url: 3},
              email: 3
            }
          ]
        }
      end

      let :schema do
        { users:
          [
            { name: String,
              site: [{url: String, title: String}, {url: Numeric}],
              email: String
            }
          ]
        }
      end

      it "reports the problem correctly" do
        expect(message).to include '/users/0/email'
      end
    end
  end
end
