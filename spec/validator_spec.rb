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
    let(:validator) do
      object = {
        foo: [
          { bar: 1 },
          { bar: 'squirrel' }
        ]
      }

      schema = {
        foo: [{bar: Numeric}]
      }

      validator = described_class.new(object, schema)
    end

    let(:message) { validator.failure_message.gsub(/\s+/,' ') }

    it 'includes the path to the point where the mismatch occurred' do
      expect(message).to include '/foo/1/bar'
    end

    it 'pinpoints the reason for the mismatch' do
      expect(message).to include 'to match Numeric but got "squirrel"'
    end

    context "when the mismatch involves a set of alternatives" do
      let(:validator) do
        object = {
          foo: [
            { bar: 123 },
            { bar: '123' },
            { bar: 'squirrel' }
          ]
        }

        schema = {
          foo: [
            { bar: [Numeric, /\d+/] }
          ]
        }

        validator = described_class.new(object, schema)
      end

      it 'includes all the alternatives in the message' do
        expect(message).to include 'to match [Numeric, /\d+/] but got "squirrel"'
      end
    end
  end
end
