RSpec.describe Kuroko2::Updater do
  let(:schedule_config) { "spec/kuroko2/schedule.rb" }
  let(:client) { double(:client) }
  let(:description) do
    <<~DESC
      This job is made from thinly sliced spam

      **Warning DO NOT EDIT**

      Please do not edit this job definition you will get spammed
    DESC
  end

  subject do
    described_class.new(
      job_list: Whenever::JobList.new(file: schedule_config),
      client: client
    )
  end

  context "first run" do
    before do
      allow(client).to receive(:list).with(%w(spam ham eggs)).and_return([])
    end

    it "creates the expcted jobs" do
      expect(client).to receive(:create).with(
        cron: ["0 0 * * *"],
        description: description,
        name: "milk::bottle",
        slack_channel: "#kuroko2-notifications",
        tags: ["spam", "ham", "eggs"],
        user_id: [1, 18, 44],
        script: <<~SCRIPT.chomp
          queue: test-executor
          docker_application: test-app-batch
          env: RAILS_ENV=production
          hako_oneshot: bundle exec rake milk::bottle
        SCRIPT
      )

      expect(client).to receive(:create).with(
        cron: ["0 0 * * *"],
        description: description,
        name: "CheeseService.melt",
        slack_channel: "#kuroko2-notifications",
        tags: ["spam", "ham", "eggs"],
        user_id: [1, 18, 44],
        script: <<~SCRIPT.chomp
          queue: test-executor
          docker_application: test-app-batch
          env: RAILS_ENV=production
          hako_oneshot: bundle exec rails runner CheeseService.melt
        SCRIPT
      )

      expect(client).to receive(:create).with(
        cron: ["0 0,3,6,9,12,15,18,21 * * *"],
        description: description,
        name: "milk::pour",
        slack_channel: "#kuroko2-notifications",
        tags: ["spam", "ham", "eggs"],
        user_id: [1, 18, 44],
        script: <<~SCRIPT.chomp
          queue: test-executor
          docker_application: test-app-batch
          env: RAILS_ENV=production
          hako_oneshot: bundle exec rake milk::pour
        SCRIPT
      )
      subject.run
    end
  end

  context "updates" do
    before do
      allow(client).to receive(:list).with(%w(spam ham eggs)).and_return([
                                                                           {
                                                                             id: 22,
                                                                             name: "CheeseService.melt"
                                                                           },
                                                                           {
                                                                             id: 56,
                                                                             name: "milk::pour"
                                                                           },
                                                                           {
                                                                             id: 88,
                                                                             name: "milk::bottle"
                                                                           }
                                                                         ])
    end

    it "updates the expcted jobs" do
      expect(client).to receive(:update).with(
        id: 88,
        cron: ["0 0 * * *"],
        description: description,
        name: "milk::bottle",
        slack_channel: "#kuroko2-notifications",
        tags: ["spam", "ham", "eggs"],
        user_id: [1, 18, 44],
        script: <<~SCRIPT.chomp
          queue: test-executor
          docker_application: test-app-batch
          env: RAILS_ENV=production
          hako_oneshot: bundle exec rake milk::bottle
        SCRIPT
      )

      expect(client).to receive(:update).with(
        id: 22,
        cron: ["0 0 * * *"],
        description: description,
        name: "CheeseService.melt",
        slack_channel: "#kuroko2-notifications",
        tags: ["spam", "ham", "eggs"],
        user_id: [1, 18, 44],
        script: <<~SCRIPT.chomp
          queue: test-executor
          docker_application: test-app-batch
          env: RAILS_ENV=production
          hako_oneshot: bundle exec rails runner CheeseService.melt
        SCRIPT
      )

      expect(client).to receive(:update).with(
        id: 56,
        cron: ["0 0,3,6,9,12,15,18,21 * * *"],
        description: description,
        name: "milk::pour",
        slack_channel: "#kuroko2-notifications",
        tags: ["spam", "ham", "eggs"],
        user_id: [1, 18, 44],
        script: <<~SCRIPT.chomp
          queue: test-executor
          docker_application: test-app-batch
          env: RAILS_ENV=production
          hako_oneshot: bundle exec rake milk::pour
        SCRIPT
      )

      subject.run
    end
  end

  context "deleting jobs" do
    let(:schedule_config) { "spec/kuroko2/empty_schedule.rb" }

    before do
      allow(client).to receive(:list).with(%w(spam ham eggs)).and_return([
                                                                           {
                                                                             id: 22
                                                                           },
                                                                           {
                                                                             id: 56
                                                                           },
                                                                           {
                                                                             id: 88
                                                                           }
                                                                         ])
    end

    it "deletes the expected jobs" do
      expect(client).to receive(:delete).with(id: 22)
      expect(client).to receive(:delete).with(id: 56)
      expect(client).to receive(:delete).with(id: 88)
      subject.run
    end
  end
end
