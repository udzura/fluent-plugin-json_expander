# fluent-plugin-jsonbreak


## Installation

Install it yourself as:

    $ fluent-gem install fluent-plugin-jsonbreak

## Usage

```xml
<match access.summary>
  type jsonbreak
  subtype growthforecast
  delete_used_key false # or true if you want to delete the key
                        # used in template construction

  <template>
    gfapi_url http://127.0.0.1:5125/api/
    graph_path ${data[mothor_host]}/${data[vhost]}/${key_name}
    name_keys count_2xx,count_3xx,count_4xx,count_5xx
  </template>
</match>
```

With data:

```json
// tag = access.summary
{
  mother_host": "kvm001.udzura.jp",
  "vhost": "front.udzura.com",
  "count_2xx": 1234,
  "count_3xx": 567,
  "...": "..."
}
```

Will extracted to below:

```xml
<match>
  type growthforecast
  gfapi_url http://127.0.0.1:5125/api/
  graph_path kvm001.udzura.jp/front.udzura.com/${key_name}
  name_keys count_2xx,count_3xx,count_4xx,count_5xx
</match>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/fluent-plugin-jsonbreak. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

