import { apiInitializer } from "discourse/lib/api";
const PLUGIN_ID = "discourse-solved-reminders-plugin";

export default apiInitializer("0.11.1", (api) => {
  api.modifyClass("controller:preferences/notifications", {
    pluginId: PLUGIN_ID,

    actions: {
      save() {
        this.saveAttrNames.push("custom_fields");
        this._super(...arguments);
      },
    },
  });
});
