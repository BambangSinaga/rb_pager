module RbPager
  module ActiveRecord
    extend ActiveSupport::Concern

    module ClassMethods

      AR_ORDER = { '+' => :asc, '-' => :desc }

      def pager(after: nil, before: nil, limit: nil, sort: nil)
        raise InvalidLimitValueError if limit && limit < 1
        instance_variable_set(:@sorted_columns, nil)
        instance_variable_set(:@collection, nil)
        instance_variable_set(:@records, nil)

        @page_limit = limit || RbPager.configuration.limit
        @sort = sort

        @after = decode(after)
        @before = decode(before)
        @direction = :next

        create_paginate_meta
      end

      private

      def decode(cursor)
        return nil if cursor.nil?

        decode = Base64.strict_decode64(cursor)
        Hash[
          decode.split(',').map do |pair|
            k, v = pair.split(':', 2)
          end
        ]
      end

      def apply_after
        return nil if @after.nil?

        if sorted_columns.values.all? :asc
          Arel::Nodes::GreaterThan.new(
            Arel::Nodes::Grouping.new(@after.keys.map{ |col| arel_table[col] }),
            Arel::Nodes::Grouping.new(@after.values.map{ |col| Arel::Nodes.build_quoted(col) })
          )
        else
          @direction = :prev
          Arel::Nodes::LessThan.new(
            Arel::Nodes::Grouping.new(@after.keys.map{|col| arel_table[col]}),
            Arel::Nodes::Grouping.new(@after.values.map{ |col| Arel::Nodes.build_quoted(col) })
          )
        end
      end

      def apply_before
        return nil if @before.nil?

        if sorted_columns.values.all? :asc
          @direction = :prev
          Arel::Nodes::LessThan.new(
            Arel::Nodes::Grouping.new(@before.keys.map{ |col| arel_table[col] }),
            Arel::Nodes::Grouping.new(@before.values.map{ |col| Arel::Nodes.build_quoted(col) })
          )
        else
          Arel::Nodes::GreaterThan.new(
            Arel::Nodes::Grouping.new(@before.keys.map{|col| arel_table[col]}),
            Arel::Nodes::Grouping.new(@before.values.map{ |col| Arel::Nodes.build_quoted(col) })
          )
        end
      end

      def sorted_columns
        @sorted_columns ||= begin
          sorted_columns = {} if @sort.nil?
          sorted_columns ||= construct_sorted_columns
        end
      end

      def construct_sorted_columns
        sorted_params = {}
        fields = @sort.split(',')

        fields.each do |field|
          sort_sign = field =~ /\A[+-]/ ? field.slice!(0) : '+'
          sorted_params[field] = AR_ORDER[sort_sign] if attribute_names.include?(field)
        end

        sorted_params
      end

      def create_paginate_meta
        cursor = cursor(collection)

        meta = { prev_cursor: cursor.first, next_cursor: cursor.last }
        [collection, meta]
      end

      def collection
        @collection ||= where(apply_after)
                        .where(apply_before)
                        .order(sorted_columns)
                        .extending(ActiveRecordRelationMethods)
                        .limit(@page_limit)
      end

      def records
        @records || collection.to_a
      end

      def cursor(collection)
        return ['', ''] if collection.total_size.zero?

        prev_cursor, next_cursor = [], []

        if sorted_columns.blank?
          prev_cursor = ["#{primary_key}:#{records.first.send(primary_key)}"]
          next_cursor = ["#{primary_key}:#{records.last.send(primary_key)}"]
        else
          sorted_columns.each do |key, _value|
            if type_for_attribute(key).type.eql? :datetime
              prev_cursor << "#{key}:#{records.first.send(key).rfc3339(9)}"
              next_cursor << "#{key}:#{records.last.send(key).rfc3339(9)}"
              next
            end

            prev_cursor << "#{key}:#{records.first.send(key)}"
            next_cursor << "#{key}:#{records.last.send(key)}"
          end
        end

        return ['', Base64.strict_encode64(next_cursor.join(','))] if (@after.nil? && @before.nil?) || @direction.eql?(:prev) && !collection.left_over?
        return [Base64.strict_encode64(prev_cursor.join(',')), ''] if @direction.eql?(:next) && !collection.left_over?

        [Base64.strict_encode64(prev_cursor.join(',')), Base64.strict_encode64(next_cursor.join(','))]
      end
    end

    module ActiveRecordRelationMethods
      def left_over?
        @left_over ||= begin
          # Cache #size otherwise multiple calls to the database will occur.
          size.positive? && size < total_size
        end
      end

      # Returns number of records that exist in scope of the current cursor
      def total_size(column_name = :all) #:nodoc:
        # #count overrides the #select which could include generated columns
        # referenced in #order, so skip #order here, where it's irrelevant to the
        # result anyway.
        @total_size ||= begin
          context = except(:offset, :limit, :order)

          # Remove includes only if they are irrelevant
          context = context.except(:includes) unless references_eager_loaded_tables?

          args = [column_name]

          # .group returns an OrderedHash that responds to #count
          context = context.count(*args)

          if context.is_a?(Hash) || context.is_a?(ActiveSupport::OrderedHash)
            context.count
          else
            context.respond_to?(:count) ? context.count(*args) : context
          end
        end
      end
    end
  end
end
