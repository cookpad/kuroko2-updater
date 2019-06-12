# Kuroko2 Updater 

## Background

A tool that uses a [whenever](https://github.com/javan/whenever) style config
file to configure [kuroko2](https://github.com/cookpad/kuroko2)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kuroko2-updater'
```

And then execute:

    $ bundle

## Status

Experimental, not intended for general use, no plans for ongoing maintenance.

## Usage

Some modifications must be made to the schedule.rb file to support using
kuroko2, rather than cron, here is an example of the additions required:


```ruby
set :job_template, <<~TEMPLATE
  queue: hako-executor
  docker_application: hello-world-batch
  env: :environment_variable=:environment
  hako_oneshot: :job
TEMPLATE

job_type :rake, "bundle exec rake :task"

# These tags scope the job definitions that will be managed with this config.
set :kuroko2_tags, %w(hello-world production scheduled)

# These are kuroku2 user ids for the Admin user(s) of the jobs managed
# by this tool. See the /users page to find the id of the
# user(s) you want to have this responsibility.
set :kuroko2_users, [1]

# This description is added to each job definition created in kuroko2 to
# warn people not to manually edit the jobs managed by this file!
set :kuroko2_job_description, <<~DESC
  This job is managed by an automation tool.

  **Warning DO NOT EDIT**

  Please do not edit this job definition directly
  but instead make a pull request to https://github.com/cookpad/hello-world/blob/master/config/schedule.rb
DESC

set :kuroko2_slack_channel, "#hello-world-alerts"
```

As part of the deployment process run the `kuroko2-updater` command.

By default this reads `config/schedule.rb` but another file can be passed as an argument.

## Config

This config is **required** and must be included in the environment for this
tool to run without error!

| Var | notes | e.g |
|-----|-------|-----|
| `KUROKO2_API_URL` | The URL of the kuroko2 API | `https://kuroko2.example.com/v1` |
| `KUROKO2_API_USER` | The username for kuroku2 API auth | `hello-world` |
| `KUROKO2_API_KEY` | The password/key for kuroku2 API auth | `secret-password` |

## Warning

This gem is currently only intended to be used internally at Cookpad. And we cannot
really recommend it's use as we created it to ease some migration issues in a
specific project.

This tool heavily monkey patches and exposes some internal details of whenever
in a way that I am sure is not supported by the author of that tool, so it
may well break unexpectedly if you update whenever!

We intend to improve this tool, or create other tooling to enable this workflow
more generically, at some point in the future.
