import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import { getOwnerWithFallback } from "discourse/lib/get-owner";
import { i18n } from "discourse-i18n";
import { registerDestructor } from "@ember/destroyable";
import { fetchDonations, loadModalScript } from "../lib/btcpay";

export default class DonateOptionCard extends Component {
  @service currentUser;

  @tracked copied = false;
  @tracked amount = "";
  @tracked submitting = false;
  @tracked modalOpen = false;
  @tracked error = null;
  @tracked liveCurrency = null;
  copyTimeout = null;

  get hasIdentity() {
    return Boolean(this.args.owner || this.args.provider);
  }

  get useBtcpay() {
    return Boolean(this.args.useBtcpay);
  }

  get showUrl() {
    return !this.useBtcpay && Boolean(this.args.url);
  }

  // One overlay at a time: a second invoice would stack a second modal.
  get busy() {
    return this.submitting || this.modalOpen;
  }

  // BTCPay charges in btcpay_donation_currency, so prefer what the plugin
  // reports over the theme's display-only currency setting.
  get currency() {
    return this.liveCurrency || settings.support_currency || "";
  }

  constructor(...args) {
    super(...args);

    if (this.useBtcpay) {
      this.loadCurrency();
    }

    registerDestructor(this, () => {
      if (this.copyTimeout) {
        clearTimeout(this.copyTimeout);
      }
    });
  }

  async loadCurrency() {
    const data = await fetchDonations();

    if (!this.isDestroying && !this.isDestroyed && data?.currency) {
      this.liveCurrency = data.currency;
    }
  }

  @action
  updateAmount(event) {
    this.amount = event.target.value;
    this.error = null;
  }

  @action
  showLogin(event) {
    event?.preventDefault();
    const login = getOwnerWithFallback(this).lookup("service:login");

    if (login?.showLogin) {
      login.showLogin();
    } else {
      window.location = "/login";
    }
  }

  @action
  async donate(event) {
    event?.preventDefault();

    if (this.busy || !this.amount) {
      return;
    }

    this.submitting = true;
    this.error = null;

    try {
      const { invoice_id, modal_url, checkout_url } = await ajax(
        "/btcpay/donate.json",
        { type: "POST", data: { amount: String(this.amount) } }
      );

      try {
        await loadModalScript(modal_url);

        if (!window.btcpay?.showInvoice) {
          throw new Error("btcpay modal unavailable");
        }

        window.btcpay.onModalWillLeave?.(() => (this.modalOpen = false));
        this.modalOpen = true;
        window.btcpay.showInvoice(invoice_id);
      } catch {
        // The plugin always returns a hosted checkout page too.
        window.location = checkout_url;
      }
    } catch (requestError) {
      this.error = extractError(requestError);
    } finally {
      this.submitting = false;
    }
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
    <article class="donate-option-card {{if @featured '--featured'}}">
      <div class="donate-option-card__top">
        <div class="donate-option-card__icon" aria-hidden="true">
          {{#if @icon}}
            <img class="donate-option-card__img" src={{@icon}} alt="" />
          {{else}}
            <span class="donate-option-card__fallback-icon">{{icon
                "heart"
              }}</span>
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
            title={{if
              this.copied
              (i18n (themePrefix "copied_value"))
              @copyLabel
            }}
            class={{if
              this.copied
              "donate-option-card__copy --copied"
              "donate-option-card__copy"
            }}
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

        {{#if this.useBtcpay}}
          {{#if this.currentUser}}
            <form
              class="donate-option-card__btcpay"
              {{on "submit" this.donate}}
            >
              <span class="donate-option-card__amount">
                <input
                  type="number"
                  inputmode="decimal"
                  min="0"
                  step="0.01"
                  value={{this.amount}}
                  disabled={{this.busy}}
                  placeholder={{i18n (themePrefix "btcpay.amount_placeholder")}}
                  aria-label={{i18n (themePrefix "btcpay.amount_label")}}
                  {{on "input" this.updateAmount}}
                />
                {{#if this.currency}}
                  <span
                    class="donate-option-card__amount-currency"
                    aria-hidden="true"
                  >
                    {{this.currency}}
                  </span>
                {{/if}}
              </span>

              <button
                type="submit"
                class="btn-primary btn btn-icon-text"
                disabled={{this.busy}}
              >
                {{if
                  this.submitting
                  (i18n (themePrefix "btcpay.creating"))
                  @buttonText
                }}
              </button>
            </form>

            {{#if this.error}}
              <p
                class="donate-option-card__error"
                role="alert"
              >{{this.error}}</p>
            {{/if}}
          {{else}}
            <button
              type="button"
              class="btn-primary btn btn-icon-text"
              {{on "click" this.showLogin}}
            >
              {{i18n (themePrefix "btcpay.login_to_donate")}}
            </button>
          {{/if}}
        {{else if this.showUrl}}
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
