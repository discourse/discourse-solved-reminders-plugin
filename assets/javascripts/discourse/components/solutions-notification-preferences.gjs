import Component, { Input } from "@ember/component";
import { i18n } from "discourse-i18n";

export default class SolutionsNotificationPreferences extends Component {
  <template>
    <div class="control-group follow-notifications">
      <label class="control-label">{{i18n
          "discourse_solved_reminders.notifications.label"
        }}</label>

      <div class="controls">
        <label class="checkbox-label">
          {{Input
            type="checkbox"
            checked=this.user.custom_fields.dont_send_accepted_solution_notifications
          }}
          {{i18n
            "discourse_solved_reminders.notifications.dont_send_accepted_solution_notifications"
          }}
        </label>
      </div>
    </div>
  </template>
}
