# frozen_string_literal: true

class SeedExistingMarkSolutionReminderState < ActiveRecord::Migration[8.0]
  def up
    return if Migration::Helpers.new_site?

    # Use the old 14-day floor so existing active sites do not resend reminders
    # for topics the previous scheduled job may have already touched.
    execute <<~SQL
      WITH settings AS (
        SELECT
          COALESCE(NULLIF((SELECT value FROM site_settings WHERE name = 'remind_mark_solution_last_post_age'), ''), '180')::integer AS last_post_age_days,
          COALESCE((SELECT value FROM site_settings WHERE name = 'solved_enabled'), 't') IN ('t', 'true') AS solved_enabled,
          COALESCE((SELECT value FROM site_settings WHERE name = 'solved_reminders_plugin_enabled'), 'f') IN ('t', 'true') AS reminders_enabled
      )
      INSERT INTO topic_custom_fields (topic_id, name, value, created_at, updated_at)
      SELECT
        topics.id,
        'solved_reminder_last_sent_at',
        CURRENT_TIMESTAMP::text,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM topics
      CROSS JOIN settings
      WHERE settings.solved_enabled
        AND settings.reminders_enabled
        AND topics.archetype <> 'private_message'
        AND topics.closed = false
        AND topics.archived = false
        AND topics.visible = true
        AND topics.posts_count > 0
        AND topics.last_post_user_id <> topics.user_id
        AND topics.last_posted_at > CURRENT_TIMESTAMP - (settings.last_post_age_days * INTERVAL '1 day')
        AND topics.last_posted_at < CURRENT_TIMESTAMP - INTERVAL '14 days'
        AND NOT EXISTS (
          SELECT 1
            FROM discourse_solved_solved_topics dsst
           WHERE dsst.topic_id = topics.id
        )
        AND NOT EXISTS (
          SELECT 1
            FROM topic_custom_fields tcf
           WHERE tcf.topic_id = topics.id
             AND tcf.name = 'solved_reminder_last_sent_at'
        )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
