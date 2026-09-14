import Component from "@glimmer/component";
import DonateContent from "./donate-content";

export default class DonatePost extends Component {
  get classes() {
    const view = this.args.view || "full";
    const design = this.args.design || "classic";
    const support = this.args.showSupportBar ? "" : "--no-support-bar";

    return [
      "donate-post",
      `--view-${view}`,
      `--design-${design}`,
      support,
    ]
      .filter(Boolean)
      .join(" ");
  }

  <template>
    <div class={{this.classes}}>
      <DonateContent
        @view={{@view}}
        @design={{@design}}
        @showSupportBar={{@showSupportBar}}
      />
    </div>
  </template>
}
