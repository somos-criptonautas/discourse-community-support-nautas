import { defaultHomepage } from "discourse/lib/utilities";

// One gate shared by the initializer and by every component that renders
// itself on arbitrary pages. The route check has to run per render, not once
// at boot: renderInOutlet registers a component a single time, so a boot-time
// check would freeze the answer from whatever page happened to load first.

export function matchesRoute(router) {
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

  // The setting is named "must contain", so a value matches anywhere in the
  // address. A lone "*" is every page; a trailing "*" from the old prefix
  // syntax is dropped, since containing the prefix already covers it.
  return configuredPaths
    .split("|")
    .filter(Boolean)
    .some((value) => value === "*" || path.includes(value.replace(/\*$/, "")));
}

export function displayForUser(currentUser) {
  return Boolean(
    (settings.show_for_members && currentUser) ||
    (settings.show_for_anon && !currentUser)
  );
}

export function meetsTrustLevel(currentUser) {
  return (
    !currentUser || currentUser.trust_level >= Number(settings.trust_level)
  );
}

export function isInExcludedGroup(currentUser) {
  if (!currentUser || !settings.excluded_groups) {
    return false;
  }

  const excludedGroupIds = settings.excluded_groups
    .split("|")
    .map((id) => parseInt(id, 10));

  return Boolean(
    currentUser.visibleGroups?.some((group) =>
      excludedGroupIds.includes(group.id)
    )
  );
}

// Who may see the component, wherever it is placed.
export function audienceAllowed(currentUser) {
  return (
    displayForUser(currentUser) &&
    meetsTrustLevel(currentUser) &&
    !isInExcludedGroup(currentUser)
  );
}

// Everything the automatic placements (plugin outlets, generic embeds) must
// satisfy. Post embeds deliberately skip this: a [wrap=donate] block was put
// on that page on purpose by whoever wrote the post.
export function shouldRenderAutomatically(router, currentUser) {
  return audienceAllowed(currentUser) && matchesRoute(router);
}
