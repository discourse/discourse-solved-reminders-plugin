# frozen_string_literal: true

describe Jobs::AnswerSimilarQuestions do
  before do
    SiteSetting.solved_enabled = true
    SiteSetting.allow_solved_on_all_topics = true
    SiteSetting.solved_reminders_plugin_enabled = true
  end

  describe "#execute" do
    fab!(:user)
    fab!(:topic) do
      Fabricate(:topic_with_op, last_post_user_id: user.id, last_posted_at: 170.days.ago)
    end
    fab!(:post) { Fabricate(:post, topic: topic, user: user) }

    before do
      5.times { Fabricate(:topic) }

      DiscourseSolved::AcceptAnswer.call!(
        params: {
          post_id: post.id,
        },
        guardian: Discourse.system_user.guardian,
      )
    end

    it "should send a PM to user suggesting more topics to answer" do
      expect { described_class.new.execute({ post_id: post.id }) }.to change { Topic.count }.by(1)
      expect(Topic.last.title).to eq(I18n.t("answer_similar_questions.title"))
      expect(Topic.last.first_post.raw).to include(
        I18n.t(
          "answer_similar_questions.message",
          solved_post_url: "#{Discourse.base_url}#{post.url}",
        ),
      )
    end
  end
end
