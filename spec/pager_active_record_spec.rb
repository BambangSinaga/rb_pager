RSpec.describe RbPager do
  it "has a version number" do
    expect(RbPager::VERSION).not_to be nil
  end

  before do
    RbPager.configure do |config|
      config.limit = 15
    end
  end

  context 'no records' do
    before { Employee.delete_all }

    it 'returns empty collection' do
      records, meta = Employee.pager

      expect(records.to_a).to be_empty
      expect(meta[:next_cursor]).to eql ''
    end
  end

  context 'with records' do
    before(:all) do
      load File.dirname(__FILE__) + '/support/seeds.rb'
    end

    let(:no_cursor) { '' }

    describe '#limit' do
      context 'limit not set' do
        it 'returns collection with default limit' do
          records, meta = Employee.pager
          next_cursor = Base64.strict_encode64("id:#{records.last.id}")

          expect(records.to_a).to eql Employee.limit(15).to_a
          expect(meta[:next_cursor]).to eql next_cursor
        end
      end

      context 'limit set to -10' do
        it 'raise InvalidParameterValueError' do
          expect { Employee.pager(limit: -10) }.to raise_error(RbPager::InvalidLimitValueError)
        end
      end

      context 'limit set to 10' do
        it 'returns collection with 10 records' do
          records, meta = Employee.pager(limit: 10)
          next_cursor = Base64.strict_encode64("id:#{records.last.id}")

          expect(records.to_a).to eql Employee.limit(10).to_a
          expect(meta[:next_cursor]).to eql next_cursor
        end
      end
    end

    describe '#after' do
      context 'order by uniq column' do
        context 'with cursor id order by asc' do
          it 'returns collection' do
            last_record = Employee.find(15)
            after = Base64.strict_encode64("created_at:#{last_record.created_at.rfc3339(9)}")

            records, meta = Employee.pager(after: after, limit: 10, sort: 'created_at')
            prev_cursor = Base64.strict_encode64("created_at:#{records.first.created_at.rfc3339(9)}")
            next_cursor = Base64.strict_encode64("created_at:#{records.last.created_at.rfc3339(9)}")

            expect(records.to_a).to eql Employee.where('created_at > ?', last_record.created_at).order(:created_at).limit(10).to_a
            expect(meta[:prev_cursor]).to eql prev_cursor
            expect(meta[:next_cursor]).to eql no_cursor
          end
        end

        context 'with cursor id order by desc' do
          it 'returns collection' do
            last_record = Employee.find(5)
            after = Base64.strict_encode64("created_at:#{last_record.created_at.rfc3339(9)}")

            records, meta = Employee.pager(after: after, limit: 10, sort: '-created_at')
            next_cursor = Base64.strict_encode64("created_at:#{records.last.created_at.rfc3339(9)}")

            expect(records.to_a).to eql Employee.where('created_at < ?', last_record.created_at).order(created_at: :desc).limit(10).to_a
            expect(meta[:prev_cursor]).to eql no_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end

        context 'without cursor' do
          it 'returns collection' do
            records, meta = Employee.pager(limit: 10, sort: 'created_at')
            next_cursor = Base64.strict_encode64("created_at:#{records.last.created_at.rfc3339(9)}")

            expect(records.to_a).to eql Employee.order(:created_at).limit(10).to_a
            expect(meta[:prev_cursor]).to eql no_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end
      end

      context 'order by not uniq column' do
        context 'with cursor name, id order by asc' do
          it 'returns collection' do
            last_record = Employee.find(5)
            after = Base64.strict_encode64("name:#{last_record.name},id:#{last_record.id}")

            records, meta = Employee.pager(after: after, limit: 10, sort: 'name,id')
            prev_cursor = Base64.strict_encode64("name:#{records.first.name},id:#{records.first.id}")
            next_cursor = Base64.strict_encode64("name:#{records.last.name},id:#{records.last.id}")

            expect(records.to_a).to eql Employee.where('(name, id) > (?, ?)', last_record.name, last_record.id).order(:name, :id).limit(10).to_a
            expect(meta[:prev_cursor]).to eql prev_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end

        context 'with cursor name, id order by desc' do
          it 'returns collection' do
            last_record = Employee.find(5)
            after = Base64.strict_encode64("name:#{last_record.name},id:#{last_record.id}")

            records, meta = Employee.pager(after: after, limit: 10, sort: '-name,-id')
            next_cursor = Base64.strict_encode64("name:#{records.last.name},id:#{records.last.id}")

            expect(records.to_a).to eql Employee.where('(name, id) < (?, ?)', last_record.name, last_record.id).order(name: :desc, id: :desc).limit(10).to_a
            expect(meta[:prev_cursor]).to eql no_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end

        context 'without cursor' do
          it 'returns collection' do
            records, meta = Employee.pager(limit: 10, sort: 'name,id')
            next_cursor = Base64.strict_encode64("name:#{records.last.name},id:#{records.last.id}")

            expect(records.to_a).to eql Employee.order(:name, :id).limit(10).to_a
            expect(meta[:prev_cursor]).to eql no_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end
      end
    end

    describe '#before' do
      context 'order by uniq column' do
        context 'with cursor id order by asc' do
          it 'returns collection' do
            first_record = Employee.find(5)
            prev = Base64.strict_encode64("created_at:#{first_record.created_at.rfc3339(9)}")

            records, meta = Employee.pager(before: prev, limit: 10, sort: 'created_at')
            next_cursor = Base64.strict_encode64("created_at:#{records.last.created_at.rfc3339(9)}")

            expect(records.to_a).to eql Employee.where('created_at < ?', first_record.created_at).order(:created_at).limit(10).to_a
            expect(meta[:prev_cursor]).to eql no_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end

        context 'with cursor id order by desc' do
          it 'returns collection' do
            first_record = Employee.find(5)
            prev = Base64.strict_encode64("created_at:#{first_record.created_at.rfc3339(9)}")

            records, meta = Employee.pager(before: prev, limit: 10, sort: '-created_at')
            prev_cursor = Base64.strict_encode64("created_at:#{records.first.created_at.rfc3339(9)}")
            next_cursor = Base64.strict_encode64("created_at:#{records.last.created_at.rfc3339(9)}")

            expect(records.to_a).to eql Employee.where('created_at > ?', first_record.created_at).order(created_at: :desc).limit(10).to_a
            expect(meta[:prev_cursor]).to eql prev_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end

        context 'without cursor' do
          it 'returns collection' do
            records, meta = Employee.pager(limit: 10, sort: 'created_at')
            next_cursor = Base64.strict_encode64("created_at:#{records.last.created_at.rfc3339(9)}")

            expect(records.to_a).to eql Employee.order(:created_at).limit(10).to_a
            expect(meta[:prev_cursor]).to eql no_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end
      end

      context 'order by not uniq column' do
        context 'with cursor name, id order by asc' do
          it 'returns collection' do
            first_record = Employee.find(5)
            prev = Base64.strict_encode64("name:#{first_record.name},id:#{first_record.id}")

            records, meta = Employee.pager(before: prev, limit: 10, sort: 'name,id')
            next_cursor = Base64.strict_encode64("name:#{records.last.name},id:#{records.last.id}")

            expect(records.to_a).to eql Employee.where('(name, id) < (?, ?)', first_record.name, first_record.id).order(:name, :id).limit(10).to_a
            expect(meta[:prev_cursor]).to eql no_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end

        context 'with cursor name, id order by desc' do
          it 'returns collection' do
            first_record = Employee.find(5)
            prev = Base64.strict_encode64("name:#{first_record.name},id:#{first_record.id}")

            records, meta = Employee.pager(before: prev, limit: 10, sort: '-name,-id')
            prev_cursor = Base64.strict_encode64("name:#{records.first.name},id:#{records.first.id}")
            next_cursor = Base64.strict_encode64("name:#{records.last.name},id:#{records.last.id}")

            expect(records.to_a).to eql Employee.where('(name, id) > (?, ?)', first_record.name, first_record.id).order(name: :desc, id: :desc).limit(10).to_a
            expect(meta[:prev_cursor]).to eql prev_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end

        context 'without cursor' do
          it 'returns collection' do
            records, meta = Employee.pager(limit: 10, sort: 'name,id')
            next_cursor = Base64.strict_encode64("name:#{records.last.name},id:#{records.last.id}")

            expect(records.to_a).to eql Employee.order(:name, :id).limit(10).to_a
            expect(meta[:prev_cursor]).to eql no_cursor
            expect(meta[:next_cursor]).to eql next_cursor
          end
        end
      end
    end
  end
end
