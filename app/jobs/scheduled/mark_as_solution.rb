# frozen_string_literal: true

module Jobs
  class MarkAsSolution < ::Jobs::Scheduled
    every 1.day

    def execute(_args = nil)
      return false unless SiteSetting.solved_enabled && SiteSetting.solved_reminders_plugin_enabled
      Rails.logger.warn("Running scheduled job to send notifications to mark a post a solution.")

      base_query =
        Topic
          .listable_topics
          .where(closed: false, archived: false, visible: true)
          .where("posts_count > 0")
          .where("last_post_user_id <> user_id")
          .where("last_posted_at > ?", SiteSetting.remind_mark_solution_last_post_age.days.ago)
          .where(
            "NOT EXISTS (SELECT 1 FROM discourse_solved_solved_topics dsst WHERE dsst.topic_id = topics.id)",
          )

      if !SiteSetting.allow_solved_on_all_topics
        category_ids =
          CategoryCustomField.where(name: "enable_accepted_answers", value: "true").select(
            :category_id,
          )

        tag_topic_ids =
          if SiteSetting.enable_solved_tags.present?
            TopicTag.where(
              tag_id: Tag.where_name(SiteSetting.enable_solved_tags.split("|")).select(:id),
            ).select(:topic_id)
          end

        base_query =
          if tag_topic_ids
            base_query.where("category_id IN (?) OR id IN (?)", category_ids, tag_topic_ids)
          else
            base_query.where(category_id: category_ids)
          end
      end

      cutoff_date = SiteSetting.remind_mark_solution_after_days.days.ago

      discobot = User.find(-2)
      base_query
        .where("COALESCE(last_posted_at, current_date) < ?", cutoff_date)
        .find_each do |topic|
          PostCreator.create!(
            discobot,
            title: I18n.t("mark_as_solution.title"),
            raw: "#{I18n.t("mark_as_solution.message")}\n\n#{topic.url}",
            archetype: Archetype.private_message,
            target_usernames: [topic.user.username],
            skip_validations: true,
          )
        end
    end
  end
end
