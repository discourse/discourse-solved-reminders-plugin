# frozen_string_literal: true

describe Jobs::AnswerSimilarQuestions do
  subject(:execute_job) { described_class.new.execute(post_id: post.id) }

  fab!(:user)
  fab!(:topic) do
    Fabricate(:topic_with_op, last_post_user_id: user.id, last_posted_at: 170.days.ago)
  end
  fab!(:post) { Fabricate(:post, topic: topic, user: user, post_number: 2) }

  let(:private_messages) { Topic.where(archetype: Archetype.private_message) }
  let(:create_solved_post_for) do
    lambda do |solver|
      solved_topic = Fabricate(:topic_with_op)
      solved_post = Fabricate(:post, topic: solved_topic, user: solver, post_number: 2)

      DiscourseSolved.accept_answer!(solved_post, Discourse.system_user)
    end
  end

  before do
    SiteSetting.solved_enabled = true
    SiteSetting.allow_solved_on_all_topics = true
    SiteSetting.solved_reminders_plugin_enabled = true
  end

  describe "#execute" do
    it "sends a PM to the solver suggesting more topics" do
      Fabricate.times(5, :topic)
      DiscourseSolved.accept_answer!(post, Discourse.system_user)

      expect { execute_job }.to change { private_messages.count }.by(1)

      private_message = private_messages.last

      aggregate_failures do
        expect(private_message.title).to eq(I18n.t("answer_similar_questions.title"))
        expect(private_message.user).to eq(Discourse.system_user)
        expect(private_message.first_post.raw).to include(
          I18n.t(
            "answer_similar_questions.message",
            solved_post_url: "#{Discourse.base_url}#{post.url}",
          ),
        )
      end
    end

    it "does not send a PM when the solver opted out" do
      user.custom_fields[SolvedReminders::USER_CUSTOM_FIELD_NAME] = true
      user.save_custom_fields
      Fabricate.times(5, :topic)
      DiscourseSolved.accept_answer!(post, Discourse.system_user)

      expect { execute_job }.to not_change { private_messages.count }
    end

    it "does not send a PM before the configured cadence" do
      SiteSetting.send_solved_pm_first_n_time = 0
      Fabricate.times(5, :topic)
      DiscourseSolved.accept_answer!(post, Discourse.system_user)

      expect { execute_job }.to not_change { private_messages.count }
    end

    it "sends a PM on the configured cadence" do
      SiteSetting.send_solved_pm_first_n_time = 0
      SiteSetting.send_solved_pm_after_every_n_time = 3
      2.times { create_solved_post_for.call(user) }
      Fabricate.times(5, :topic)
      DiscourseSolved.accept_answer!(post, Discourse.system_user)

      expect { execute_job }.to change { private_messages.count }.by(1)
    end

    it "does not raise when the solved post no longer exists" do
      expect { described_class.new.execute(post_id: -1) }.to not_change { private_messages.count }
    end
  end
end
