RSpec.describe Kuroko2::Updater do
  it "has a version number" do
    expect(Kuroko2::Updater::VERSION).not_to be nil
  end

  let(:whenever_job_list) do
    double(
      :job_list,
      time_and_jobs: time_and_jobs,
      kuroko2_users: [17, 22],
      kuroko2_tags: %w(foo bar baz),
      kuroko2_slack_channel: "#random",
      kuroko2_job_description: "This job was created by a robot army, don't edit it or you may anger them"
    )
  end

  let(:kuroko2_jobs) { [] }

  let(:client) do
    double(:client, list: kuroko2_jobs)
  end

  subject do
    described_class.new(job_list: whenever_job_list, client: client)
  end

  context "jobs are configured in the schedule.rb but not on kuroko2" do
    let(:time_and_jobs) do
      {
        day: [
          double(:job, task: "cheese:update", at: nil, output: "bundle exec rake cheese:update")
        ],
        30.minutes => [
          double(:job, task: "cream:churn", at: nil, output: "bundle exec rake cream:churn")
        ]
      }
    end

    it "creates the jobs" do
      expect(client).to receive(:create).with(
        name: "cheese:update",
        script: "bundle exec rake cheese:update",
        cron: ["0 0 * * *"],
        user_id: [17, 22],
        description: whenever_job_list.kuroko2_job_description,
        tags: %w(foo bar baz),
        slack_channel: "#random"
      )

      expect(client).to receive(:create).with(
        name: "cream:churn",
        script: "bundle exec rake cream:churn",
        cron: ["0,30 * * * *"],
        user_id: [17, 22],
        description: whenever_job_list.kuroko2_job_description,
        tags: %w(foo bar baz),
        slack_channel: "#random"
      )
      subject.run
    end
  end

  context "defaulted values" do
    let(:whenever_job_list) do
      double(
        :job_list,
        time_and_jobs: time_and_jobs,
        kuroko2_users: [17, 22],
        kuroko2_tags: %w(foo bar baz)
      )
    end

    let(:time_and_jobs) do
      {
        day: [
          double(:job, task: "cheese:update", at: nil, output: "bundle exec rake cheese:update")
        ]
      }
    end

    before do
      allow(whenever_job_list).to receive(:kuroko2_slack_channel).and_raise NoMethodError
      allow(whenever_job_list).to receive(:kuroko2_job_description).and_raise NoMethodError
    end

    it "defaults the slack channel to nil" do
      expect(client).to receive(:create).with(hash_including(slack_channel: nil))
      subject.run
    end

    it "defaults the job description to a useful message" do
      expect(client).to receive(:create).with(
        hash_including(
          description: <<~DESC
            This job is managed by an automation tool.

            **Warning DO NOT EDIT**

            Please do not edit this job definition directly.
          DESC
        )
      )
      subject.run
    end
  end

  context "creating a new job with the time specified by 'at'" do
    let(:time_and_jobs) do
      {
        day: [
          double(:job, task: "cheese:update", at: "9 am", output: "")
        ]
      }
    end

    it "creates the job definition with the correct cron" do
      expect(client).to receive(:create).with(
        hash_including(
          name: "cheese:update",
          cron: ["0 9 * * *"]
        )
      )
      subject.run
    end
  end

  context "creating a new job with several times specfied with 'at'" do
    let(:time_and_jobs) do
      {
        day: [
          double(:job, task: "cheese:update", at: ["07:00 am", "15:00 pm", "23:00 pm"], output: "")
        ]
      }
    end

    it "creates the job with multiple cron schedules" do
      expect(client).to receive(:create).with(
        hash_including(
          name: "cheese:update",
          cron: ["0 7 * * *", "0 15 * * *", "0 23 * * *"]
        )
      )
      subject.run
    end
  end

  context "the same task is specified multiple times" do
    let(:time_and_jobs) do
      {
        day: [
          double(:job, task: "cheese:update", at: ["07:00 am", "15:00 pm", "23:00 pm"], output: "")
        ],
        week: [
          double(:job, task: "cheese:update", at: ["22:00"], output: "")
        ]
      }
    end

    it "raises a validation error" do
      expect { subject.run }.to raise_error Kuroko2::Updater::ValidationError, "cheese:update was specified more than once"
    end
  end

  context "no tags are set" do
    let(:time_and_jobs) { {} }
    let(:whenever_job_list) do
      double(
        :job_list,
        time_and_jobs: time_and_jobs,
        kuroko2_users: [17, 22]
      )
    end

    before do
      allow(whenever_job_list).to receive(:kuroko2_tags).and_raise NoMethodError
    end

    it "raises a validation error" do
      expect { subject.run }.to raise_error Kuroko2::Updater::ValidationError, ":kuroko2_tags was not set set in the config file"
    end
  end

  context "tags are set to an empty array" do
    let(:time_and_jobs) { {} }
    let(:whenever_job_list) do
      double(
        :job_list,
        time_and_jobs: time_and_jobs,
        kuroko2_users: [17, 22],
        kuroko2_tags: []
      )
    end

    it "raises a validation error" do
      expect { subject.run }.to raise_error Kuroko2::Updater::ValidationError, ":kuroko2_tags was not set set in the config file"
    end
  end

  context "no users are set" do
    let(:time_and_jobs) { {} }
    let(:whenever_job_list) do
      double(
        :job_list,
        time_and_jobs: time_and_jobs,
        kuroko2_tags: %w(spam egg chips)
      )
    end

    before do
      allow(whenever_job_list).to receive(:kuroko2_users).and_raise NoMethodError
    end

    it "raises a validation error" do
      expect { subject.run }.to raise_error Kuroko2::Updater::ValidationError, ":kuroko2_users was not set in the config file"
    end
  end

  context "users are set to an empty array" do
    let(:time_and_jobs) { {} }
    let(:whenever_job_list) do
      double(
        :job_list,
        time_and_jobs: time_and_jobs,
        kuroko2_users: [],
        kuroko2_tags: %w(spam egg chips)
      )
    end

    it "raises a validation error" do
      expect { subject.run }.to raise_error Kuroko2::Updater::ValidationError, ":kuroko2_users was not set in the config file"
    end
  end

  context "a job is setup on kuroko2 but not in the whenever config" do
    let(:kuroko2_jobs) do
      [
        {
          id: 17,
          name: "cheese:update",
          cron: ["0 0 * * *"],
          user_id: [17, 22],
          tags: %w(foo bar baz)
        }
      ]
    end

    let(:time_and_jobs) do
      {}
    end

    it "deletes the job" do
      expect(client).to receive(:delete) do |args|
        expect(args[:id]).to eq(17)
      end
      subject.run
    end
  end

  context "a job is setup on kuroko2 and in the whenever config" do
    let(:kuroko2_jobs) do
      [
        {
          id: 17,
          name: "cheese:update",
          cron: ["0 0 * * *"],
          user_id: [17, 22],
          tags: %w(foo bar baz)
        }
      ]
    end

    let(:time_and_jobs) do
      {
        day: [
          double(:job, task: "cheese:update", at: "17:30", output: "script output")
        ]
      }
    end

    it "updates the job" do
      expect(client).to receive(:update).with(
        id: 17,
        name: "cheese:update",
        script: "script output",
        cron: ["30 17 * * *"],
        description: whenever_job_list.kuroko2_job_description,
        slack_channel: "#random",
        user_id: [17, 22],
        tags: %w(foo bar baz)
      )
      subject.run
    end
  end
end
