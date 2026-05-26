# frozen_string_literal: true

module Jobs
  class AnswerSimilarQuestions < ::Jobs::Base
    def execute(args)
      return if !SiteSetting.solved_enabled || !SiteSetting.solved_reminders_plugin_enabled

      solved_post = Post.find_by(id: args[:post_id])
      return if solved_post.blank?

      user = solved_post.user
      return if user.custom_fields[SolvedReminders::USER_CUSTOM_FIELD_NAME]

      solved_count = DiscourseSolved::Queries.solved_count(user.id)
      return if !send_similar_questions_message?(solved_count)

      suggested_topics = TopicQuery.new(user).list_suggested_for(solved_post.topic)&.topics
      return if suggested_topics.blank? || suggested_topics.one?

      raw =
        I18n.t(
          "answer_similar_questions.message",
          solved_post_url: "#{Discourse.base_url}#{solved_post.url}",
        )
      suggested_topics.each { |suggested_topic| raw << "\n\n#{suggested_topic.url}" }
      raw << "\n\n#{I18n.t("answer_similar_questions.unsubscribe", base_url: Discourse.base_url)}"

      PostCreator.create!(
        Discourse.system_user,
        title: I18n.t("answer_similar_questions.title"),
        raw: raw,
        archetype: Archetype.private_message,
        target_usernames: [user.username],
        skip_validations: true,
      )
    end

    private

    def send_similar_questions_message?(solved_count)
      solved_count <= SiteSetting.send_solved_pm_first_n_time ||
        (solved_count % SiteSetting.send_solved_pm_after_every_n_time) == 0
    end
  end
end
