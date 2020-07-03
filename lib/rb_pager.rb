require 'active_record'
require 'rb_pager/version'
require "rb_pager/configuration"

module RbPager
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end
end

if defined?(ActiveRecord)
  require 'rb_pager/orm/pager_active_record'
  ActiveRecord::Base.send :include, RbPager::ActiveRecord
end