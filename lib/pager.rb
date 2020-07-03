require 'active_record'
require 'pager/version'
require "pager/configuration"

module Pager
  class Error < StandardError; end
end

if defined?(ActiveRecord)
  require 'pager/orm/pager_active_record'
  ActiveRecord::Base.send :include, Pager::ActiveRecord
end
