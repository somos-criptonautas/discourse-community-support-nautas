import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";
import { fetchDonations } from "../lib/btcpay";
import DonateSupporterAvatars from "./donate-supporter-avatars";

export default class DonateSupportBar extends Component {
  // Live total from discourse-btcpay-subscriptions; stays null when the
  // plugin isn't installed, so the manual setting keeps working.
  @tracked liveTotal = null;
  @tracked liveCurrency = null;
  // The manual setting and the live total rarely agree, so showing the
  // setting first means flashing a number that is about to be corrected.
  // Hold the figures back until the request settles; the section itself is
  // already laid out, so nothing moves when they arrive.
  @tracked loadingTotal = true;

  constructor(owner, args) {
    super(owner, args);
    this.loadLiveTotal();
  }

  async loadLiveTotal() {
    const data = await fetchDonations();

    if (this.isDestroying || this.isDestroyed) {
      return;
    }

    if (data?.total != null) {
      this.liveTotal = Math.max(0, Number(data.total) || 0);
      this.liveCurrency = data.currency || null;
    }

    this.loadingTotal = false;
  }

  get goal() {
    return Math.max(0, Number(settings.support_goal) || 0);
  }

  get current() {
    return this.liveTotal ?? Math.max(0, Number(settings.support_current) || 0);
  }

  get rawPercentage() {
    if (!this.goal) {
      return 0;
    }
    return (this.current / this.goal) * 100;
  }

  get percentage() {
    return Math.round(this.rawPercentage);
  }

  get progressWidth() {
    if (!this.hasGoal || this.loadingTotal) {
      return 0;
    }

    const percentage = this.rawPercentage;

    if (percentage < 100) {
      return Math.min(100, Math.max(0, percentage));
    }

    const remainder = percentage % 100;

    // Keep exact 100/200/300... values visually full instead of restarting at 0.
    if (remainder < 0.000001 || 100 - remainder < 0.000001) {
      return 100;
    }

    return remainder;
  }

  get progressStyle() {
    return htmlSafe(`width: ${this.progressWidth}%;`);
  }

  get progressTrackClass() {
    if (this.rawPercentage < 100) {
      return "--track-tertiary";
    }

    const remainder = this.rawPercentage % 100;
    const isExactHundred = remainder < 0.000001 || 100 - remainder < 0.000001;

    return isExactHundred ? "--track-success" : "--track-success-low";
  }

  get progressFillClass() {
    return this.rawPercentage < 100 ? "--fill-tertiary" : "--fill-success";
  }

  get overGoal() {
    return this.hasGoal && this.current > this.goal;
  }

  get hasGoal() {
    return this.goal > 0;
  }

  get reached() {
    return this.hasGoal && this.current >= this.goal;
  }

  get layout() {
    return this.args.layout || settings.support_bar_layout || "inline";
  }

  get rootClasses() {
    return [
      "donate-support-bar",
      `--layout-${this.layout}`,
      this.loadingTotal ? "--loading" : null,
      this.overGoal ? "--goal-exceeded" : null,
      this.reached ? "--goal-reached" : null,
    ]
      .filter(Boolean)
      .join(" ");
  }

  get amountText() {
    return this.formatAmount(this.current);
  }

  get goalText() {
    return this.formatAmount(this.goal);
  }

  formatAmount(amount) {
    const currency = settings.support_currency || this.liveCurrency || "";
    const formatter = new Intl.NumberFormat(undefined, {
      maximumFractionDigits: 0,
    });
    return `${formatter.format(amount)}${currency ? ` ${currency}` : ""}`;
  }

  get periodText() {
    const key = settings.support_period || "monthly";
    return i18n(themePrefix(`support_bar.period_${key}`));
  }

  <template>
    {{#if this.hasGoal}}
      <section
        class={{this.rootClasses}}
        aria-label={{if
          settings.support_label
          settings.support_label
          (i18n (themePrefix "support_bar.default_label"))
        }}
      >
        {{! Figures and percentage sit together: the raised total, what it is
            measured against, and how far along it is, read as one sentence. }}
        <div
          class="donate-support-bar__summary"
          aria-busy={{this.loadingTotal}}
        >
          {{#if this.loadingTotal}}
            <span
              class="donate-support-bar__figures --placeholder"
              aria-hidden="true"
            >
              <span class="donate-support-bar__skeleton --amount"></span>
              <span class="donate-support-bar__skeleton --goal"></span>
            </span>
            <span
              class="donate-support-bar__skeleton --percentage"
              aria-hidden="true"
            ></span>
          {{else}}
            <span class="donate-support-bar__figures">
              <strong>{{this.amountText}}</strong>
              <span>
                {{#if this.overGoal}}
                  {{i18n (themePrefix "support_bar.goal_exceeded")}}
                {{else if this.reached}}
                  {{i18n (themePrefix "support_bar.goal_reached")}}
                {{else}}
                  {{i18n (themePrefix "support_bar.of_goal")}}
                  {{this.goalText}}
                {{/if}}
                ·
                {{this.periodText}}
              </span>
            </span>

            <strong
              class="donate-support-bar__percentage"
            >{{this.percentage}}%</strong>
          {{/if}}
        </div>

        <div
          class="donate-support-bar__track {{this.progressTrackClass}}"
          role="progressbar"
          aria-valuemin="0"
          aria-valuemax="100"
          aria-valuenow={{if this.overGoal 100 this.percentage}}
          aria-valuetext="{{this.percentage}}%"
          aria-label={{i18n (themePrefix "support_bar.progress_label")}}
        >
          <span class="donate-support-bar__fills" aria-hidden="true">
            <span
              class="donate-support-bar__fill {{this.progressFillClass}}"
              style={{this.progressStyle}}
            ></span>
          </span>
        </div>

        {{#if settings.supporter_avatars_enabled}}
          <DonateSupporterAvatars />
        {{/if}}
      </section>
    {{/if}}
  </template>
}
