import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "extend-for-solved-reminders",

  initialize() {
    withPluginApi((api) => {
      api.addSaveableCustomFields("notifications");
    });
  },
};
