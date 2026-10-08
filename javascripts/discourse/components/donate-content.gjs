import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import DonateMethodAction from "./donate-method-action";
import DonateOptionCard from "./donate-option-card";
import DonateSupportBar from "./donate-support-bar";

export default class DonateContent extends Component {
  get locale() {
    return typeof I18n !== "undefined" && I18n.locale ? I18n.locale : "en";
  }

  get view() {
    return this.args.view || "full";
  }

  get isSidebar() {
    return this.view === "sidebar";
  }

  get design() {
    return this.args.design || settings.design || "classic";
  }

  get showSupportBar() {
    return settings.support_bar_enabled && (this.args.showSupportBar ?? true);
  }

  get supportIcon() {
    return settings.support_icon || "heart";
  }

  get sidebarTitle() {
    return settings.support_label || i18n(themePrefix("sidebar.title"));
  }

  localizeMethod(method) {
    const translations = method.translations || [];
    const locale = this.locale;
    const baseLocale = locale.split(/[-_]/)[0];
    const translation =
      translations.find((item) => item.locale === locale) ||
      translations.find((item) => item.locale === baseLocale) ||
      translations.find((item) => item.locale === "en") ||
      translations[0];

    if (!translation) {
      return method;
    }

    return {
      ...method,
      name: translation.name || method.name,
      description: translation.description || method.description,
      button_text: translation.button_text || method.button_text,
      copy_label: translation.copy_label || method.copy_label,
      copy_value: method.copy_value || "",
      owner: translation.owner || method.owner,
      provider: translation.provider || method.provider,
    };
  }

  get supportHighlights() {
    const highlights = settings.support_highlights || [];
    const locale = this.locale;
    const baseLocale = locale.split(/[-_]/)[0];

    return highlights
      .map((highlight) => {
        const translations = highlight.translations || [];
        const translation =
          translations.find((item) => item.locale === locale) ||
          translations.find((item) => item.locale === baseLocale) ||
          translations.find((item) => item.locale === "en") ||
          translations[0];

        return {
          ...highlight,
          text: translation?.text || highlight.text,
        };
      })
      .filter((highlight) => highlight.text);
  }

  get donationMethods() {
    return (settings.donation_methods || []).map((method) =>
      this.localizeMethod(method)
    );
  }

  // The method whose amount field and button sit inside the box itself.
  get featuredMethod() {
    return this.donationMethods.find((method) => method.featured) || null;
  }

  get otherDonationMethods() {
    const methods = this.donationMethods;
    const featured = methods.find((method) => method.featured);
    return methods.filter((method) => method !== featured);
  }

  get rootClasses() {
    return [
      "donate-component",
      `--view-${this.view}`,
      `--design-${this.design}`,
    ].join(" ");
  }

  <template>
    <div class={{this.rootClasses}}>
      {{#if this.isSidebar}}
        <section
          class="donate-sidebar"
          aria-label={{i18n (themePrefix "support_bar.aria_label")}}
        >
          <div class="donate-sidebar__head">
            <span class="donate-sidebar__icon" aria-hidden="true">{{icon
                this.supportIcon
              }}</span>
            <strong>{{this.sidebarTitle}}</strong>
          </div>

          {{#if this.showSupportBar}}
            <DonateSupportBar @layout="compact" />
          {{/if}}

          {{#if this.featuredMethod}}
            <DonateMethodAction
              @buttonText={{this.featuredMethod.button_text}}
              @url={{this.featuredMethod.url}}
              @copyLabel={{this.featuredMethod.copy_label}}
              @copyValue={{this.featuredMethod.copy_value}}
              @useBtcpay={{this.featuredMethod.use_btcpay}}
              @useStripe={{this.featuredMethod.use_stripe}}
            />
          {{/if}}
        </section>
      {{else}}
        {{! The box is the hero and the featured method in one: copy on the
            left, the amount field and button on the right. }}
        <section class="donate-modal__hero">
          <div
            class="donate-modal__hero-glow donate-modal__hero-glow--one"
            aria-hidden="true"
          ></div>
          <div
            class="donate-modal__hero-glow donate-modal__hero-glow--two"
            aria-hidden="true"
          ></div>

          <div class="donate-modal__hero-icon" aria-hidden="true">
            {{icon this.supportIcon}}
          </div>

          <div class="donate-modal__hero-copy">
            <h2>{{i18n (themePrefix "hero.title")}}</h2>
            <p>{{trustHTML
                (i18n (themePrefix "main_heading_content.description"))
              }}</p>

            {{#if this.supportHighlights.length}}
              <div
                class="donate-modal__hero-pills"
                aria-label={{i18n (themePrefix "hero.highlights_label")}}
              >
                {{#each this.supportHighlights as |highlight|}}
                  <span>{{icon highlight.icon}} {{highlight.text}}</span>
                {{/each}}
              </div>
            {{/if}}
          </div>

          {{#if this.featuredMethod}}
            <div class="donate-modal__hero-action">
              <DonateMethodAction
                @buttonText={{this.featuredMethod.button_text}}
                @url={{this.featuredMethod.url}}
                @copyLabel={{this.featuredMethod.copy_label}}
                @copyValue={{this.featuredMethod.copy_value}}
                @useBtcpay={{this.featuredMethod.use_btcpay}}
                @useStripe={{this.featuredMethod.use_stripe}}
              />
            </div>
          {{/if}}
        </section>

        {{#if this.showSupportBar}}
          <DonateSupportBar @layout={{@supportBarLayout}} />
        {{/if}}

        {{#if this.otherDonationMethods.length}}
          <div class="donate-modal__inner">
            <div class="donate-modal__grid" role="list">
              {{#each this.otherDonationMethods as |method|}}
                <DonateOptionCard
                  @name={{method.name}}
                  @description={{method.description}}
                  @buttonText={{method.button_text}}
                  @url={{method.url}}
                  @icon={{method.icon}}
                  @owner={{method.owner}}
                  @provider={{method.provider}}
                  @copyLabel={{method.copy_label}}
                  @copyValue={{method.copy_value}}
                  @useBtcpay={{method.use_btcpay}}
                  @useStripe={{method.use_stripe}}
                />
              {{/each}}
            </div>
          </div>
        {{/if}}
      {{/if}}
    </div>
  </template>
}
