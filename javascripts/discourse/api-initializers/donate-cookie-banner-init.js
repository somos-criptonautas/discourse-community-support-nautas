import { apiInitializer } from "discourse/lib/api";
import {
  displayForUser,
  isInExcludedGroup,
  matchesRoute,
  meetsTrustLevel,
} from "../lib/visibility";
import DonateModal from "../components/modal/donate-modal";
import DonatePost from "../components/donate-post";
import DonateOutlet from "../components/donate-outlet";
import DonateWidgetPortal from "../components/donate-widget-portal";

const VIEW_NAMES = new Set([
  "full",
  "compact",
  "minimal",
  "progress",
  "sidebar",
]);
const WRAP_VIEWS = {
  donate: "full",
  "donate-compact": "compact",
  "donate-minimal": "minimal",
  "donate-progress": "progress",
};

export default apiInitializer("1.15.0", (api) => {
  const router = api.container.lookup("service:router");
  const modal = api.container.lookup("service:modal");
  const currentUser = api.getCurrentUser();

  function openModal(event) {
    event?.preventDefault();
    event?.stopPropagation();

    modal.show(DonateModal);
  }

  function handleDonateClick(event) {
    const link = event.target.closest?.('a[href="#donate"]');
    if (
      !link ||
      !meetsTrustLevel(currentUser) ||
      !displayForUser(currentUser) ||
      !matchesRoute(router)
    ) {
      return;
    }

    openModal(event);
  }

  function resolveView(value, fallback = "full") {
    return VIEW_NAMES.has(value) ? value : fallback;
  }

  function resolveDesign(value) {
    const allowed = new Set(["classic", "minimal", "modern"]);
    return allowed.has(value) ? value : settings.design || "classic";
  }

  function enhanceEmbedTarget(target, helper) {
    const wrapView = WRAP_VIEWS[target.dataset.wrap || ""];
    const view = resolveView(
      target.dataset.view || wrapView,
      settings.default_post_view || "full"
    );
    const design = resolveDesign(target.dataset.design);
    const showSupportBar = settings.support_bar_in_posts;

    target.classList.add(
      "donate-embed",
      `--view-${view}`,
      `--design-${design}`,
      showSupportBar && settings.support_bar_enabled
        ? "--support-bar"
        : "--no-support-bar"
    );
    target.replaceChildren();
    helper.renderGlimmer(target, DonatePost, {
      view,
      design,
      showSupportBar: showSupportBar && settings.support_bar_enabled,
    });
  }

  // The per-page checks live in DonateOutlet so they re-run on navigation;
  // only the group check is stable enough to decide registration up front.
  if (
    settings.outlet_enabled &&
    settings.outlet_locations &&
    !isInExcludedGroup(currentUser)
  ) {
    settings.outlet_locations
      .split("|")
      .map((outlet) => outlet.trim())
      .filter(Boolean)
      .forEach((outlet) => api.renderInOutlet(outlet, DonateOutlet));
  }

  if (settings.enable_post_embed) {
    api.decorateCookedElement((element, helper) => {
      const targets = new Set();

      element.querySelectorAll("[data-wrap]").forEach((target) => {
        if (WRAP_VIEWS[target.dataset.wrap]) {
          targets.add(target);
        }
      });

      targets.forEach((target) => enhanceEmbedTarget(target, helper));
    });
  }

  if (settings.embed_widget_enabled) {
    api.renderInOutlet("above-main-container", DonateWidgetPortal);
  }

  document.addEventListener("click", handleDonateClick);

  return () => {
    document.removeEventListener("click", handleDonateClick);
  };
});
