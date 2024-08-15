# frozen_string_literal: true

# name: discourse-solved-reminders-plugin
# about: A plugin to remind users to mark a solution
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :solved_reminders_plugin_enabled

module ::SolvedReminders
  PLUGIN_NAME = "discourse-solved-reminders-plugin".freeze
  USER_CUSTOM_FIELD_NAME = "dont_send_accepted_solution_notifications"
end

require_relative "lib/solved_reminders/engine"

after_initialize do
  require_relative "app/jobs/regular/answer_similar_questions"
  require_relative "app/jobs/scheduled/mark_as_solution"

  on(:accepted_solution) { |post| Jobs.enqueue(:answer_similar_questions, post_id: post.id) }

  User.register_custom_field_type(SolvedReminders::USER_CUSTOM_FIELD_NAME, :boolean)
  register_editable_user_custom_field(SolvedReminders::USER_CUSTOM_FIELD_NAME)
  DiscoursePluginRegistry.serialized_current_user_fields << SolvedReminders::USER_CUSTOM_FIELD_NAME
end
