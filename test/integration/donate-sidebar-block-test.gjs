import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import DonateSidebarBlock from "../../discourse/components/donate-sidebar-block";

module(
  "Community Support | Integration | donate-sidebar-block",
  function (hooks) {
    setupRenderingTest(hooks);

    let previous;

    hooks.beforeEach(function () {
      previous = {
        show_for_members: settings.show_for_members,
        show_for_anon: settings.show_for_anon,
        display_on_homepage: settings.display_on_homepage,
        url_must_contain: settings.url_must_contain,
      };
      Object.assign(settings, {
        show_for_members: true,
        show_for_anon: true,
        // A page the route rule would reject.
        display_on_homepage: false,
        url_must_contain: "/nowhere",
      });
    });

    hooks.afterEach(function () {
      Object.assign(settings, previous);
    });

    test("renders wherever Right Sidebar Blocks places it", async function (assert) {
      await render(<template><DonateSidebarBlock /></template>);

      assert
        .dom(".donate-embed.--view-sidebar .donate-sidebar__head")
        .exists("url_must_contain does not hide it; show_in_routes decides");
    });

    test("still respects who may see it", async function (assert) {
      settings.show_for_members = false;
      settings.show_for_anon = false;

      await render(<template><DonateSidebarBlock /></template>);

      assert.dom(".donate-sidebar").doesNotExist();
    });
  }
);
