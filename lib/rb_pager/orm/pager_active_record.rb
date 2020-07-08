module RbPager
  module ActiveRecord
    extend ActiveSupport::Concern

    module ClassMethods
      AR_ORDER = { '+' => :asc, '-' => :desc }
      AREL_ORDER = { asc: :gt, desc: :lt }

      def pager(after: nil, limit: nil, sort: nil)
        raise InvalidLimitValueError if limit && limit < 1
        instance_variable_set(:@sorted_columns, nil)

        page_limit = limit || RbPager.configuration.limit
        @sort = sort
        collection = if after.nil?
                       order(sorted_columns).extending(ActiveRecordRelationMethods).limit(page_limit)
                     else
                       custom_expression = create_custom_expression(after)
                       where(custom_expression).order(sorter).extending(ActiveRecordRelationMethods).limit(page_limit)
                     end

        create_paginate_meta(collection)
      end

      private

      def create_custom_expression(cursor_params)
        decode_cursor_params = JSON.parse(Base64.strict_decode64(cursor_params))
        return arel_table[primary_key].gt(decode_cursor_params[primary_key]) if sorted_columns.blank?

        filter_ordered_columns = filter_with_ordered_columns(decode_cursor_params)
        filter_primary_key = filter_with_primary_key(decode_cursor_params)

        filter_ordered_columns.or(filter_primary_key)
      end

      def filter_with_ordered_columns(decode_cursor_params)
        result = self
        sorted_columns.each_with_index do |(column, type), index|
          result = if index.zero?
                     result.arel_table[column].send(AREL_ORDER[type])
                   else
                     result.or(arel_table[column].send(AREL_ORDER[type]))
                   end
        end

        result
      end

      def filter_with_primary_key(decode_cursor_params)
        result = self

        decode_cursor_params.each_with_index do |(column, value), index|
          result = if index.zero?
                     result.arel_table[column].gt(value)
                   else
                     result.and(arel_table[column].eq(value))
                   end
        end

        result
      end

      def sorted_columns
        @sorted_columns ||= begin
          sorted_columns = {} if @sort.nil?
          sorted_columns ||= construct_sorted_columns
        end
      end

      def construct_sorted_columns
        sorted_params = {}
        fields = @sort.split(',') & attribute_names

        fields.each do |field|
          sort_sign = field =~ /\A[+-]/ ? field.slice!(0) : '+'
          sorted_params[field] = AR_ORDER[sort_sign]
        end

        sorted_params
      end

      def create_paginate_meta(collection)
        next_cursor = next_cursor(collection)

        meta = { next_cursor: next_cursor }
        [collection, meta]
      end

      def next_cursor(collection)
        return '' unless collection.left_over?

        next_cursor = { 'id': collection.last.id }

        sorted_columns.each do |key, _value|
          next_cursor.merge!(Hash[key, collection.last.send(key)])
        end

        Base64.strict_encode64(next_cursor.to_json)
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
