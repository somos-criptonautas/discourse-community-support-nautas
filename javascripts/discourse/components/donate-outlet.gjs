import Component from "@glimmer/component";
import DonateContent from "./donate-content";

const VALID_VIEWS = new Set(["full", "compact", "minimal", "progress"]);
const VALID_DESIGNS = new Set(["classic", "minimal", "modern"]);

export default class DonateOutlet extends Component {
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
    <div class={{this.classes}}>
      <DonateContent
        @view={{this.view}}
        @design={{this.design}}
        @showSupportBar={{this.showSupportBar}}
      />
    </div>
  </template>
}
