
# Pager


Cursor-based pagination (aka keyset pagination) is a  [common](https://slack.engineering/evolving-api-pagination-at-slack-1c1f644f8e12)  [pagination strategy](https://www.citusdata.com/blog/2016/03/30/five-ways-to-paginate/)  that avoids many of the pitfalls of “offset–limit” pagination.

For example, with offset–limit pagination, if an item from a prior page is deleted while the client is paginating, all subsequent results will be shifted forward by one. Therefore, when the client requests the next page, there’s one result that it will skip over and never see. Conversely, if a result is added to the list of results as the client is paginating, the client may see the same result multiple times, on different pages. Cursor-based pagination can prevent both of these possibilities.

Cursor-based pagination also performs better for large data sets under most implementations.

To support cursor-based pagination, this specification defines three query parameters `after`, `limit`, `sort`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pager'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pager

Add the [pager.rb](https://github.com/BambangSinaga/pager/blob/master/lib/config/pager.rb)

If you use Rails, put it into the `config/initializers` dir

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/BambangSinaga/pager. This project is intended to be a safe, welcoming space for collaboration, and contributors.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
