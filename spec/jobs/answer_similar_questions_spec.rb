# frozen_string_literal: true

require "rails_helper"

describe Jobs::AnswerSimilarQuestions do
  before do
    SiteSetting.solved_enabled = true
    SiteSetting.allow_solved_on_all_topics = true
    SiteSetting.solved_reminders_plugin_enabled = true
  end

  describe "#execute" do
    fab!(:user)
    fab!(:topic) { Fabricate(:topic, last_post_user_id: user.id, last_posted_at: 170.days.ago) }
    fab!(:post) { Fabricate(:post, topic: topic, user: user) }

    before { 5.times { Fabricate(:topic) } }

    it "should send a PM to user suggesting more topics to answer" do
      DiscourseSolved.accept_answer!(post, Discourse.system_user)
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
