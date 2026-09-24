import { apiInitializer } from "discourse/lib/api";
import cookie, { removeCookie } from "discourse/lib/cookie";
import { defaultHomepage } from "discourse/lib/utilities";
import DonateModal from "../components/modal/donate-modal";
import DonatePost from "../components/donate-post";
import DonateOutlet from "../components/donate-outlet";
import DonateWidgetPortal from "../components/donate-widget-portal";

const VIEW_NAMES = new Set(["full", "compact", "minimal", "progress"]);
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

  let autoOpenTimeout = null;
  let autoOpenAttempted = false;

  function cookieExpirationDate() {
    if (settings.cookie_lifespan === "none") {
      removeCookie("donate_trigger_closed", { path: "/" });
      return null;
    }

    return moment().add(1, settings.cookie_lifespan).toDate();
  }

  function dismiss() {
    const expires = cookieExpirationDate();
    if (expires) {
      cookie("donate_trigger_closed", "true", { expires, path: "/" });
    }
  }

  function displayForUser() {
    return (
      (settings.show_for_members && currentUser) ||
      (settings.show_for_anon && !currentUser)
    );
  }

  function showOnRoute() {
    const path = router.currentURL || "";

    if (
      settings.display_on_homepage &&
      router.currentRouteName === `discovery.${defaultHomepage()}`
    ) {
      return true;
    }

    const configuredPaths = settings.url_must_contain || "";
    if (!configuredPaths.length) {
      return false;
    }

    return configuredPaths.split("|").some((allowedPath) => {
      if (allowedPath.slice(-1) === "*") {
        return path.indexOf(allowedPath.slice(0, -1)) === 0;
      }
      return path === allowedPath;
    });
  }

  function isInExcludedGroup() {
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

  function meetsTrustLevel() {
    return (
      !currentUser || currentUser.trust_level >= Number(settings.trust_level)
    );
  }

  function shouldShow() {
    return (
      meetsTrustLevel() &&
      displayForUser() &&
      showOnRoute() &&
      !isInExcludedGroup()
    );
  }

  function openModal(event) {
    event?.preventDefault();
    event?.stopPropagation();

    modal.show(DonateModal, {
      model: {
        onClose: dismiss,
      },
    });
  }

  function handleDonateClick(event) {
    const link = event.target.closest?.('a[href="#donate"]');
    if (!link || !displayForUser() || !showOnRoute()) {
      return;
    }

    openModal(event);
  }

  function maybeAutoOpen() {
    if (
      !settings.auto_open_modal ||
      !shouldShow() ||
      cookie("donate_trigger_closed") ||
      autoOpenAttempted ||
      autoOpenTimeout
    ) {
      return;
    }

    const delay = Math.max(0, Number(settings.auto_open_delay) || 0);

    autoOpenTimeout = setTimeout(() => {
      autoOpenTimeout = null;
      autoOpenAttempted = true;

      if (
        !settings.auto_open_modal ||
        !shouldShow() ||
        cookie("donate_trigger_closed")
      ) {
        return;
      }

      openModal();
    }, delay);
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

  if (
    settings.outlet_enabled &&
    settings.outlet_locations &&
    !isInExcludedGroup()
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
  maybeAutoOpen();
  router.on("routeDidChange", maybeAutoOpen);

  return () => {
    document.removeEventListener("click", handleDonateClick);
    router.off("routeDidChange", maybeAutoOpen);
    if (autoOpenTimeout) {
      clearTimeout(autoOpenTimeout);
    }
  };
});
