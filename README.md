# Ec2StatsJob

We had this cron job that was updating a couple of ec2 tags with boot info.
I made a version where I was adding some server stats to be available straight from the AWS console.

Of course, I was a bit afraid of the performance hit this could cause. but it turns out, it did not cause any, and I really love this feature.

That script was pushed via chef unto multiple project, which we are now moving away from. And I wanted an easy way to share it among projects without relying on custom deployment scripts.

Making it an ActiveJob was the easiest.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ec2_stats_job'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ec2_stats_job

## Usage

```ruby
linux_user_name = 'rails'
Ec2StatsJob::Job.perform_later(linux_user_name)
```

if you are using [Sidekiq::Cron](https://github.com/ondrejbartas/sidekiq-cron), you can do in your favorite initializer

```ruby
  Sidekiq::Cron::Job.create(
    name: 'EC2 Server Stats update - every 2min',
    cron: '*/2 * * * *',
    class: 'Ec2StatsJob::Job',
    args: ['webapp']
  )
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ec2_stats_job.
