module RbPager
  module ActiveRecord
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
