require "bundler/setup"
require "rb_pager"

ActiveRecord::Base.establish_connection(
  DATABASE_URL ||
  { adapter: "postgresql", database: "rb_pager_test" }
)

load File.dirname(__FILE__) + '/support/schema.rb'
load File.dirname(__FILE__) + '/support/model.rb'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
