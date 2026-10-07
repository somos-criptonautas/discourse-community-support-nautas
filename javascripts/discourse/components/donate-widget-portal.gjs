import Component from "@glimmer/component";
import { bind } from "discourse/lib/decorators";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import DonatePost from "./donate-post";
import { shouldRenderAutomatically } from "../lib/visibility";

const SELECTOR = '[data-donation-widget="support"]';
const VALID_VIEWS = new Set([
  "full",
  "compact",
  "minimal",
  "progress",
  "sidebar",
]);
const VALID_DESIGNS = new Set(["classic", "minimal", "modern"]);

function resolveView(value) {
  return VALID_VIEWS.has(value) ? value : settings.default_post_view || "full";
}

function resolveDesign(value) {
  return VALID_DESIGNS.has(value) ? value : settings.design || "classic";
}

export default class DonateWidgetPortal extends Component {
  @service currentUser;
  @service router;
  @tracked entries = [];

  observer = null;
  scanScheduled = false;

  constructor() {
    super(...arguments);
    this.scan();
    this.observer = new MutationObserver(() => this.scheduleScan());
    this.observer.observe(document.body, { childList: true, subtree: true });
    // The route gate is part of scan(), so a navigation has to re-run it.
    this.router.on("routeDidChange", this.scheduleScan);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.observer?.disconnect();
    this.router.off("routeDidChange", this.scheduleScan);
  }

  @bind
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

  scan() {
    if (!shouldRenderAutomatically(this.router, this.currentUser)) {
      if (this.entries.length) {
        this.entries = [];
      }
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
