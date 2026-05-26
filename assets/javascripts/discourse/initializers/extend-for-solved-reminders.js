import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "extend-for-solved-reminders",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.solved_reminders_plugin_enabled) {
      return;
    }

    withPluginApi((api) => {
      api.addSaveableCustomFields("notifications");
    });
  },
};
