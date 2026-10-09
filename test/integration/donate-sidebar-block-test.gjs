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
      // Rendering tests build a bare user with no trust level; real users
      // always carry one, and trust_level 0 is the setting's default.
      this.currentUser.trust_level = 0;

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

    test("drops its own frame inside Right Sidebar Blocks only", async function (assert) {
      await render(
        <template>
          <div class="rs-component rs-donate-sidebar-block">
            <DonateSidebarBlock />
          </div>
          <div class="standalone"><DonateSidebarBlock /></div>
        </template>
      );

      const border = (selector) =>
        getComputedStyle(document.querySelector(selector)).borderTopWidth;

      assert.strictEqual(
        border(".standalone .donate-sidebar"),
        "1px",
        "framed on its own (also proves the theme CSS is loaded)"
      );
      assert.strictEqual(
        border(".rs-donate-sidebar-block .donate-sidebar"),
        "0px",
        "no second frame inside Right Sidebar Blocks"
      );
    });

    test("still respects who may see it", async function (assert) {
      settings.show_for_members = false;
      settings.show_for_anon = false;

      await render(<template><DonateSidebarBlock /></template>);

      assert.dom(".donate-sidebar").doesNotExist();
    });
  }
);
