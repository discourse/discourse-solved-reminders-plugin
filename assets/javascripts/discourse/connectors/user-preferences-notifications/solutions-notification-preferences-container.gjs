import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import SolutionsNotificationPreferences from "../../components/solutions-notification-preferences";

@tagName("div")
@classNames(
  "user-preferences-notifications-outlet",
  "solutions-notification-preferences-container"
)
export default class SolutionsNotificationPreferencesContainer extends Component {
  static shouldRender(_, context) {
    return context.siteSettings.solved_reminders_plugin_enabled;
  }

  <template><SolutionsNotificationPreferences @user={{this.model}} /></template>
}
