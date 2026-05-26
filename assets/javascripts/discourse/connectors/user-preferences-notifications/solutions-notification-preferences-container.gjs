import Component from "@glimmer/component";
import PreferenceCheckbox from "discourse/components/preference-checkbox";
import { i18n } from "discourse-i18n";

export default class SolutionsNotificationPreferencesContainer extends Component {
  static shouldRender(_args, { siteSettings }) {
    return siteSettings.solved_reminders_plugin_enabled;
  }

  <template>
    <div class="control-group solved-reminders-notifications">
      <label class="control-label">{{i18n
          "discourse_solved_reminders.notifications.label"
        }}</label>

      <PreferenceCheckbox
        @labelKey="discourse_solved_reminders.notifications.dont_send_accepted_solution_notifications"
        @checked={{@outletArgs.model.custom_fields.dont_send_accepted_solution_notifications}}
        data-setting-name="user-dont-send-accepted-solution-notifications"
        class="pref-dont-send-accepted-solution-notifications"
      />
    </div>
  </template>
}
