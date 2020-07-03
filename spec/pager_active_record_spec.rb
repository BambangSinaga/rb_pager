RSpec.describe Pager do
  it "has a version number" do
    expect(Pager::VERSION).not_to be nil
  end

  context 'no records' do
    before { Employee.delete_all }

    it 'returns empty collection' do
      records, meta = Employee.pager(after: nil, limit: nil)

      expect(records).to be_empty
      expect(meta[:next_cursor]).to eql ''
    end
  end

  context 'with records' do
    before(:all) do
      load File.dirname(__FILE__) + '/support/seeds.rb'
    end

    context 'limit not set' do
      it 'returns collection with default limit' do
        records, meta = Employee.pager(after: nil, limit: nil)
        next_cursor = Base64.strict_encode64({ 'id': records.last.id }.to_json)

        expect(records).to eql Employee.limit(15).to_a
        expect(meta[:next_cursor]).to eql next_cursor
      end
    end

    context 'limit set to 10' do
      it 'returns collection with 10 records' do
        records, meta = Employee.pager(after: nil, limit: 10)
        next_cursor = Base64.strict_encode64({ 'id': records.last.id }.to_json)

        expect(records).to eql Employee.limit(10).to_a
        expect(meta[:next_cursor]).to eql next_cursor
      end
    end

    context 'order by uniq column' do
      it 'returns collection' do
        records, meta = Employee.pager(after: nil, limit: 10, sort: 'created_at')
        next_cursor = Base64.strict_encode64(
          { 'id': records.last.id, 'created_at': records.last.created_at }.to_json
        )

        expect(records).to eql Employee.order(:created_at).limit(10).to_a
        expect(meta[:next_cursor]).to eql next_cursor
      end
    end

    context 'order by not uniq column' do
      it 'returns collection' do
        records, meta = Employee.pager(after: nil, limit: 10, sort: 'name,id')
        next_cursor = Base64.strict_encode64(
          { 'id': records.last.id, 'name': records.last.name }.to_json
        )
        # binding.pry
        expect(records).to eql Employee.order(:name, :id).limit(10).to_a
        expect(meta[:next_cursor]).to eql next_cursor
      end
    end
  end
end
