import { action } from "@ember/object";
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  api.modifyClass(
    "controller:preferences/notifications",
    (Superclass) =>
      class extends Superclass {
        @action
        save() {
          this.saveAttrNames.push("custom_fields");
          super.save(...arguments);
        }
      }
  );
});
