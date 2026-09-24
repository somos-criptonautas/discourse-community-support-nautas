import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import DonateOptionCard from "./donate-option-card";
import DonateSupportBar from "./donate-support-bar";

export default class DonateContent extends Component {
  get locale() {
    return typeof I18n !== "undefined" && I18n.locale ? I18n.locale : "en";
  }

  get view() {
    return this.args.view || "full";
  }

  get design() {
    return this.args.design || settings.design || "classic";
  }

  get showSupportBar() {
    return settings.support_bar_enabled && (this.args.showSupportBar ?? true);
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
      {{#if this.showSupportBar}}
        <DonateSupportBar @layout={{@supportBarLayout}} />
      {{/if}}

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
          {{icon "heart"}}
        </div>

        <div class="donate-modal__hero-copy">
          <div class="donate-modal__eyebrow">
            <span>{{i18n (themePrefix "hero.eyebrow")}}</span>
          </div>
          <h2>{{i18n (themePrefix "hero.title")}}</h2>
          <p>{{trustHTML
              (i18n (themePrefix "main_heading_content.description"))
            }}</p>
        </div>

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
      </section>

      <div class="donate-modal__inner">
        {{#if this.featuredMethod}}
          <section
            class="donate-modal__featured"
            aria-labelledby="donate-featured-title"
          >
            <div class="donate-modal__section-intro">
              <span class="donate-modal__section-kicker">{{i18n
                  (themePrefix "featured.kicker")
                }}</span>
              <h3 id="donate-featured-title">{{this.featuredMethod.name}}</h3>
              <p>{{this.featuredMethod.description}}</p>
            </div>

            <DonateOptionCard
              @featured={{true}}
              @name={{this.featuredMethod.name}}
              @description={{this.featuredMethod.description}}
              @buttonText={{this.featuredMethod.button_text}}
              @url={{this.featuredMethod.url}}
              @icon={{this.featuredMethod.icon}}
              @owner={{this.featuredMethod.owner}}
              @provider={{this.featuredMethod.provider}}
              @copyLabel={{this.featuredMethod.copy_label}}
              @copyValue={{this.featuredMethod.copy_value}}
              @useBtcpay={{this.featuredMethod.use_btcpay}}
            />
          </section>
        {{/if}}

        {{#if this.otherDonationMethods.length}}
          <section
            class="donate-modal__methods"
            aria-labelledby="donate-methods-title"
          >
            <div class="donate-modal__methods-heading">
              <div>
                <span>{{i18n (themePrefix "methods.kicker")}}</span>
                <h3 id="donate-methods-title">{{i18n
                    (themePrefix "methods.title")
                  }}</h3>
              </div>
              <span
                class="donate-modal__methods-count"
              >{{this.otherDonationMethods.length}}</span>
            </div>

            <div class="donate-modal__grid">
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
                />
              {{/each}}
            </div>
          </section>
        {{/if}}

        <div class="donate-modal__closing">
          {{icon "heart"}}
          <span>{{i18n (themePrefix "footer.thanks")}}</span>
        </div>
      </div>
    </div>
  </template>
}
