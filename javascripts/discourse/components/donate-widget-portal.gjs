import Component from "@glimmer/component";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import DonatePost from "./donate-post";

const SELECTOR = '[data-donation-widget="support"]';
const VALID_VIEWS = new Set(["full", "compact", "minimal", "progress"]);
const VALID_DESIGNS = new Set(["classic", "minimal", "modern"]);

function resolveView(value) {
  return VALID_VIEWS.has(value) ? value : settings.default_post_view || "full";
}

function resolveDesign(value) {
  return VALID_DESIGNS.has(value) ? value : settings.design || "classic";
}

export default class DonateWidgetPortal extends Component {
  @service currentUser;
  @tracked entries = [];

  observer = null;
  scanScheduled = false;

  constructor() {
    super(...arguments);
    this.scan();
    this.observer = new MutationObserver(() => this.scheduleScan());
    this.observer.observe(document.body, { childList: true, subtree: true });
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.observer?.disconnect();
  }

  scheduleScan() {
    if (this.scanScheduled) {
      return;
    }
    this.scanScheduled = true;
    requestAnimationFrame(() => {
      this.scanScheduled = false;
      this.scan();
    });
  }

  get isExcludedGroupMember() {
    const currentUser = this.currentUser;
    if (!currentUser || !settings.excluded_groups) {
      return false;
    }

    const excludedGroupIds = settings.excluded_groups
      .split("|")
      .map((id) => parseInt(id, 10));

    return currentUser.visibleGroups?.some((group) =>
      excludedGroupIds.includes(group.id)
    );
  }

  scan() {
    if (this.isExcludedGroupMember) {
      this.entries = [];
      return;
    }

    const found = [...document.querySelectorAll(SELECTOR)];

    const changed =
      found.length !== this.entries.length ||
      found.some((el, i) => el !== this.entries[i]?.el);

    if (!changed) {
      return;
    }

    const showSupportBar =
      settings.support_bar_enabled && settings.support_bar_in_embeds;

    this.entries = found.map((el) => {
      const view = resolveView(el.dataset.view);
      const design = resolveDesign(el.dataset.design);

      el.classList.add(
        "donate-embed",
        `--view-${view}`,
        `--design-${design}`,
        showSupportBar ? "--support-bar" : "--no-support-bar"
      );

      return { el, view, design, showSupportBar };
    });
  }

  <template>
    {{#each this.entries key="el" as |entry|}}
      {{#in-element entry.el}}
        <DonatePost
          @view={{entry.view}}
          @design={{entry.design}}
          @showSupportBar={{entry.showSupportBar}}
        />
      {{/in-element}}
    {{/each}}
  </template>
}
