import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import DMenu from "discourse/float-kit/components/d-menu";
import { renderAvatar } from "discourse/helpers/user-avatar";
import { i18n } from "discourse-i18n";
import { fetchDonations } from "../lib/btcpay";

const userCache = new Map();

export default class DonateSupporterAvatars extends Component {
  @service site;
  @tracked supporters = [];
  @tracked isLoading = true;

  constructor(owner, args) {
    super(owner, args);
    this.loadSupporters();
  }

  get configuredSupporters() {
    return Array.isArray(settings.supporters) ? settings.supporters : [];
  }

  get configuredGroupIds() {
    return String(settings.supporter_groups || "")
      .split("|")
      .map((id) => parseInt(id, 10))
      .filter((id) => Number.isInteger(id) && id > 0);
  }

  get visibleCount() {
    return Math.max(1, Number(settings.supporter_avatar_count) || 5);
  }

  get showAmounts() {
    return settings.show_supporter_amounts;
  }

  get visibleSupporters() {
    return this.supporters.slice(0, this.visibleCount);
  }

  get remainingCount() {
    return Math.max(0, this.supporters.length - this.visibleSupporters.length);
  }

  get shouldShow() {
    return (
      settings.supporter_avatars_enabled &&
      !this.isLoading &&
      this.supporters.length > 0
    );
  }

  get shouldShowPlaceholder() {
    return settings.supporter_avatars_enabled && this.isLoading;
  }

  get placeholderSlots() {
    return Array.from({ length: this.visibleCount });
  }

  get moreLabel() {
    return `+${this.remainingCount}`;
  }

  formatAmount(supporter) {
    if (!supporter.amount) {
      return "";
    }

    const formatter = new Intl.NumberFormat(undefined, {
      maximumFractionDigits: 0,
    });
    return `${formatter.format(supporter.amount)}${supporter.currency ? ` ${supporter.currency}` : ""}`;
  }

  async loadSupporters() {
    if (!settings.supporter_avatars_enabled) {
      this.isLoading = false;
      return;
    }

    try {
      const sources = await Promise.all([
        this.loadManualSupporters(),
        this.loadBtcpaySupporters(),
        this.loadGroupSupporters(),
      ]);

      // Earlier sources win on a username conflict: a manual entry can carry
      // an offline amount, and a real donation beats a group membership.
      const seen = new Set();
      this.supporters = sources.flat().filter((supporter) => {
        const key = supporter.username.toLowerCase();
        if (seen.has(key)) {
          return false;
        }
        seen.add(key);
        return true;
      });
    } finally {
      this.isLoading = false;
    }
  }

  async loadManualSupporters() {
    const entries = this.configuredSupporters;
    if (!entries.length) {
      return [];
    }

    const resolved = await Promise.all(
      entries.map(async (entry) => {
        const username = String(entry.username || "").trim();
        if (!username) {
          return null;
        }

        try {
          if (!userCache.has(username.toLowerCase())) {
            userCache.set(
              username.toLowerCase(),
              fetch(`/u/${encodeURIComponent(username)}.json`, {
                credentials: "same-origin",
                headers: { Accept: "application/json" },
              }).then(async (response) => {
                if (!response.ok) {
                  return null;
                }
                // Discourse wraps the payload under a "user" key
                // (UsersController#show serializes with root: "user"),
                // so the actual fields live at data.user, not at the
                // top level.
                const data = await response.json();
                return data?.user ?? null;
              })
            );
          }

          const user = await userCache.get(username.toLowerCase());
          if (!user) {
            return null;
          }
          const resolvedUsername = user.username || username;
          const resolvedName = user.name || resolvedUsername;

          return {
            username: resolvedUsername,
            name: resolvedName,
            avatar_template: user.avatar_template,
            amount: Math.max(0, Number(entry.amount) || 0),
            currency: entry.currency || "",
            profileUrl: `/u/${encodeURIComponent(resolvedUsername)}`,
            initial: resolvedName.slice(0, 1).toUpperCase(),
          };
        } catch {
          return null;
        }
      })
    );

    return resolved.filter(Boolean);
  }

  // Real donations recorded by discourse-btcpay-subscriptions. Empty when the
  // plugin isn't installed, leaving the manual list as the only source.
  async loadBtcpaySupporters() {
    const data = await fetchDonations();
    const supporters = Array.isArray(data?.supporters) ? data.supporters : [];

    return supporters
      .filter((entry) => entry.username)
      .map((entry) => ({
        username: entry.username,
        name: entry.username,
        avatar_template: entry.avatar_template,
        amount: Math.max(0, Number(entry.amount) || 0),
        currency: data.currency || "",
        profileUrl: `/u/${encodeURIComponent(entry.username)}`,
        initial: entry.username.slice(0, 1).toUpperCase(),
      }));
  }

  async loadGroupSupporters() {
    const groupIds = this.configuredGroupIds;
    if (!groupIds.length) {
      return [];
    }

    const groups = groupIds
      .map((id) => this.site.groups?.find((group) => group.id === id))
      .filter(Boolean);

    const memberLists = await Promise.all(
      groups.map((group) => this.fetchGroupMembers(group.name))
    );

    const combined = memberLists
      .flat()
      .map((member) => {
        const resolvedName = member.name || member.username;
        return {
          username: member.username,
          name: resolvedName,
          avatar_template: member.avatar_template,
          amount: 0,
          currency: "",
          profileUrl: `/u/${encodeURIComponent(member.username)}`,
          initial: resolvedName.slice(0, 1).toUpperCase(),
          addedAt: member.added_at,
        };
      })
      // Newest member of the group first.
      .sort((a, b) => new Date(b.addedAt) - new Date(a.addedAt));

    const seen = new Set();
    return combined.filter((supporter) => {
      const key = supporter.username.toLowerCase();
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    });
  }

  async fetchGroupMembers(groupName) {
    try {
      const response = await fetch(
        `/groups/${encodeURIComponent(groupName)}/members.json?order=added_at&asc=false&limit=1000`,
        {
          credentials: "same-origin",
          headers: { Accept: "application/json" },
        }
      );
      if (!response.ok) {
        return [];
      }
      const data = await response.json();
      return Array.isArray(data?.members) ? data.members : [];
    } catch {
      return [];
    }
  }

  <template>
    {{#if this.shouldShowPlaceholder}}
      <div
        class="donate-supporters donate-supporters--loading"
        aria-hidden="true"
      >
        <div class="donate-supporters__avatars">
          {{#each this.placeholderSlots}}
            <span
              class="donate-supporters__avatar donate-supporters__avatar--placeholder"
            ></span>
          {{/each}}
        </div>
      </div>
    {{else if this.shouldShow}}
      <div
        class="donate-supporters"
        aria-label={{i18n (themePrefix "supporters.label")}}
      >
        <div class="donate-supporters__avatars" role="list">
          {{#each this.visibleSupporters as |supporter|}}
            <a
              href={{supporter.profileUrl}}
              data-user-card={{supporter.username}}
              class="donate-supporters__avatar"
              title={{supporter.name}}
              aria-label={{supporter.name}}
              role="listitem"
            >
              {{#if supporter.avatar_template}}
                {{htmlSafe
                  (renderAvatar
                    supporter
                    avatarTemplatePath="avatar_template"
                    usernamePath="username"
                    imageSize="tiny"
                  )
                }}
              {{else}}
                <span aria-hidden="true">{{supporter.initial}}</span>
              {{/if}}
            </a>
          {{/each}}
        </div>

        {{#if this.remainingCount}}
          <DMenu
            identifier="community-supporters"
            @label={{this.moreLabel}}
            @ariaLabel={{i18n
              (themePrefix "supporters.more_label")
              count=this.remainingCount
            }}
            @title={{i18n (themePrefix "supporters.more_title")}}
            @class="btn-transparent donate-supporters__more-button"
            @contentClass="donate-supporters__menu-content"
            @modalForMobile={{true}}
          >
            <:content>
              <div class="donate-supporters__list">
                <div class="donate-supporters__list-heading">
                  <strong>{{i18n (themePrefix "supporters.title")}}</strong>
                  <span>{{this.supporters.length}}</span>
                </div>

                {{#each this.supporters as |supporter|}}
                  <a
                    href={{supporter.profileUrl}}
                    data-user-card={{supporter.username}}
                    class="donate-supporters__item"
                  >
                    <span
                      class="donate-supporters__item-avatar"
                      aria-hidden="true"
                    >
                      {{#if supporter.avatar_template}}
                        {{htmlSafe
                          (renderAvatar
                            supporter
                            avatarTemplatePath="avatar_template"
                            usernamePath="username"
                            imageSize="medium"
                          )
                        }}
                      {{else}}
                        <span>{{supporter.initial}}</span>
                      {{/if}}
                    </span>
                    <span class="donate-supporters__item-copy">
                      <strong>{{supporter.name}}</strong>
                      {{#if this.showAmounts}}
                        {{#if supporter.amount}}
                          <span>{{this.formatAmount supporter}}</span>
                        {{/if}}
                      {{/if}}
                    </span>
                  </a>
                {{/each}}
              </div>
            </:content>
          </DMenu>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
