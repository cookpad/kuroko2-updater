set :job_template, <<~TEMPLATE
  queue: test-executor
  docker_application: test-app-batch
  env: :environment_variable=:environment
  hako_oneshot: :job
TEMPLATE

job_type :rake, "bundle exec rake :task"
job_type :runner, "bundle exec rails runner :task"

set :kuroko2_tags, %w(spam ham eggs)
set :kuroko2_users, [1, 18, 44]

set :kuroko2_job_description, <<~DESC
  This job is made from thinly sliced spam

  **Warning DO NOT EDIT**

  Please do not edit this job definition you will get spammed
DESC

set :kuroko2_slack_channel, "#kuroko2-notifications"

every :day, at: "07:00,15:00,23:00" do
  rake "milk::bottle"
  runner "CheeseService.melt"
end

every 3.hours, at: ["00:01"] do
  rake "milk::pour"
end

every "monday,wednesday,friday", at: "9:00 am" do
  rake "yogurt::open"
end
