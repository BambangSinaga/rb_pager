module Pager
  module ActiveRecord
    extend ActiveSupport::Concern

    module ClassMethods
      AR_ORDER = { '+' => :asc, '-' => :desc }
      AREL_ORDER = { asc: :gt, desc: :lt }

      def pager(after:, limit:, sort: nil)
        page_limit = limit || Pager.configuration.limit
        sort_params = sort
        sorted_columns, sorter = build_order_expression(sort)
        collection = if after.nil?
                       order(sorter).extending(ActiveRecordRelationMethods).limit(page_limit)
                     else
                       custom_expression = create_custom_expression(after, sorted_columns)
                       where(custom_expression).order(sorter).extending(ActiveRecordRelationMethods).limit(page_limit)
                     end

        create_paginate_meta(collection, sorted_columns)
      end

      private

      def create_custom_expression(cursor_params, sorted_columns)
        decode_cursor_params = JSON.parse(Base64.strict_decode64(cursor_params))
        return arel_table[primary_key].gt(decode_cursor_params[primary_key]) if sorted_columns.blank?

        filter_ordered_columns = filter_with_ordered_columns(decode_cursor_params, sorted_columns)
        filter_primary_key = filter_with_primary_key(decode_cursor_params)

        filter_ordered_columns.or(filter_primary_key)
      end

      def filter_with_ordered_columns(decode_cursor_params, sorted_columns)
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

      def build_order_expression(sort_params)
        return {} if sort_params.nil?

        sort_order = { '+' => 'ASC', '-' => 'DESC' }
        sorted_params = {}
        arel_orders = []

        sort_params.split(',').each do |field|
          next unless attribute_names.include?(field)

          sort_sign = field =~ /\A[+-]/ ? field.slice!(0) : '+'
          arel_orders << arel_table[field].send(AR_ORDER[sort_sign])
          sorted_params[field] = AR_ORDER[sort_sign]
        end

        [sorted_params, arel_orders]
      end

      def create_paginate_meta(collection, sorted_columns)
        next_cursor = next_cursor(collection, sorted_columns)

        meta = { next_cursor: next_cursor }
        [collection.to_a, meta]
      end

      def next_cursor(collection, sorted_columns)
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
