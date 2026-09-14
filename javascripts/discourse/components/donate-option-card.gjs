import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import { getOwnerWithFallback } from "discourse/lib/get-owner";
import { i18n } from "discourse-i18n";
import { registerDestructor } from "@ember/destroyable";

export default class DonateOptionCard extends Component {
  @tracked copied = false;
  copyTimeout = null;

  get hasIdentity() {
    return Boolean(this.args.owner || this.args.provider);
  }

  get showUrl() {
    return Boolean(this.args.url);
  }

  constructor(...args) {
    super(...args);
    registerDestructor(this, () => {
      if (this.copyTimeout) {
        clearTimeout(this.copyTimeout);
      }
    });
  }

  @action
  async copyValue() {
    if (!this.args.copyValue) {
      return;
    }

    try {
      await navigator.clipboard.writeText(this.args.copyValue);
      this.copied = true;

      if (this.copyTimeout) {
        clearTimeout(this.copyTimeout);
      }

      this.copyTimeout = setTimeout(() => {
        this.copied = false;
        this.copyTimeout = null;
      }, 1800);
    } catch (error) {
      console.error("Failed to copy donation value", error);
      const dialog = getOwnerWithFallback(this).lookup("service:dialog");
      const message = i18n(themePrefix("no_copied_value"));

      if (dialog?.alert) {
        dialog.alert(message);
      }
    }
  }

  <template>
    <article class="donate-option-card {{if @featured "--featured"}}">
      <div class="donate-option-card__top">
        <div class="donate-option-card__icon" aria-hidden="true">
          {{#if @icon}}
            <img class="donate-option-card__img" src={{@icon}} alt="" />
          {{else}}
            <span class="donate-option-card__fallback-icon">{{icon "heart"}}</span>
          {{/if}}
        </div>

        {{#if this.hasIdentity}}
          <div class="donate-option-card__identity">
            {{#if @owner}}<strong>{{@owner}}</strong>{{/if}}
            {{#if @provider}}<span>{{@provider}}</span>{{/if}}
          </div>
        {{/if}}
      </div>

      <div class="donate-option-card__content">
        {{#unless @featured}}
          <h3>{{@name}}</h3>
          <p>{{@description}}</p>
        {{/unless}}

        {{#if @copyValue}}
          <button
            type="button"
            {{on "click" this.copyValue}}
            title={{if this.copied (i18n (themePrefix "copied_value")) @copyLabel}}
            class={{if this.copied "donate-option-card__copy --copied" "donate-option-card__copy"}}
          >
            <span class="donate-option-card__copy-content">
              <span class="donate-option-card__copy-label">{{@copyLabel}}</span>
              <span class="donate-option-card__copy-value">{{@copyValue}}</span>
            </span>
            <span class="donate-option-card__copy-icon" aria-hidden="true">
              {{icon (if this.copied "check" "copy")}}
            </span>
            <span class="sr-only">
              {{if this.copied (i18n (themePrefix "copied_value")) @copyLabel}}
            </span>
          </button>
        {{/if}}

        {{#if this.showUrl}}
          <a
            href={{@url}}
            target="_blank"
            rel="noopener noreferrer"
            class="btn-primary btn btn-icon-text"
          >
            {{@buttonText}}
          </a>
        {{/if}}
      </div>
    </article>
  </template>
}
