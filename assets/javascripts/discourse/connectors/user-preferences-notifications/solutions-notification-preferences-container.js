export default {
  shouldRender(_, component) {
    return component.siteSettings.solved_reminders_plugin_enabled;
  },
};
