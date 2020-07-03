require 'active_record'
require 'pager/version'
require "pager/configuration"

module Pager
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
  require 'pager/orm/pager_active_record'
  ActiveRecord::Base.send :include, Pager::ActiveRecord
end
