import Component from "@glimmer/component";
import { service } from "@ember/service";
import DonateContent from "./donate-content";
import { shouldRenderAutomatically } from "../lib/visibility";

const VALID_VIEWS = new Set([
  "full",
  "compact",
  "minimal",
  "progress",
  "sidebar",
]);
const VALID_DESIGNS = new Set(["classic", "minimal", "modern"]);

export default class DonateOutlet extends Component {
  @service router;
  @service currentUser;

  // renderInOutlet registers this component once, so the audience and route
  // checks have to live here to re-run as the user navigates.
  get shouldRender() {
    return shouldRenderAutomatically(this.router, this.currentUser);
  }

  get design() {
    const value = settings.outlet_design || settings.design || "classic";
    return VALID_DESIGNS.has(value) ? value : "classic";
  }

  get view() {
    const value = settings.outlet_view || "compact";
    return VALID_VIEWS.has(value) ? value : "compact";
  }

  get showSupportBar() {
    return settings.support_bar_enabled && settings.support_bar_in_outlets;
  }

  get classes() {
    return [
      "donate-outlet",
      "donate-embed",
      `--design-${this.design}`,
      `--view-${this.view}`,
      this.showSupportBar ? "" : "--no-support-bar",
    ]
      .filter(Boolean)
      .join(" ");
  }

  <template>
    {{#if this.shouldRender}}
      <div class={{this.classes}}>
        <DonateContent
          @view={{this.view}}
          @design={{this.design}}
          @showSupportBar={{this.showSupportBar}}
        />
      </div>
    {{/if}}
  </template>
}
