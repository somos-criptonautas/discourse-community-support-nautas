import Component from "@glimmer/component";
import { service } from "@ember/service";
import { audienceAllowed } from "../lib/visibility";
import DonateContent from "./donate-content";

// A block for the core team's discourse-right-sidebar-blocks component, which
// renders its blocks by name through the resolver and passes them no required
// arguments. To place it, add {"name": "donate-sidebar-block"} to that
// component's `blocks` setting. The name has to stay unique: the resolver
// takes the first module whose path ends in components/<name>.
//
// The .donate-embed wrapper is not decoration — every base style in this
// component is scoped under it.
export default class DonateSidebarBlock extends Component {
  @service currentUser;

  // Who sees it, not where: Right Sidebar Blocks already decides which pages
  // show its column (show_in_routes). Checking url_must_contain as well
  // hid the block on pages where the admin had placed it.
  get shouldRender() {
    return audienceAllowed(this.currentUser);
  }

  get design() {
    return settings.design || "classic";
  }

  get showSupportBar() {
    return settings.support_bar_enabled && settings.support_bar_in_outlets;
  }

  <template>
    {{#if this.shouldRender}}
      <div class="donate-embed --view-sidebar --design-{{this.design}}">
        <DonateContent
          @view="sidebar"
          @design={{this.design}}
          @showSupportBar={{this.showSupportBar}}
        />
      </div>
    {{/if}}
  </template>
}
