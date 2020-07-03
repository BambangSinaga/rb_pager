module RbPager
  class Configuration
    attr_accessor :limit, :max_limit

    def initialize
      @limit = 20
      @max_limit = 100
    end

    def limit=(val)
      @limit = [val, @max_limit].min
    end
  end
end