import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import DonateMethodAction from "./donate-method-action";

export default class DonateOptionCard extends Component {
  get hasIdentity() {
    return Boolean(this.args.owner || this.args.provider);
  }

  get fallbackIcon() {
    return settings.support_icon || "heart";
  }

  <template>
    <article class="donate-option-card">
      <div class="donate-option-card__top">
        <div class="donate-option-card__icon" aria-hidden="true">
          {{#if @icon}}
            <img class="donate-option-card__img" src={{@icon}} alt="" />
          {{else}}
            <span class="donate-option-card__fallback-icon">{{icon
                this.fallbackIcon
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
        <h3>{{@name}}</h3>
        <p>{{@description}}</p>

        <DonateMethodAction
          @buttonText={{@buttonText}}
          @url={{@url}}
          @copyLabel={{@copyLabel}}
          @copyValue={{@copyValue}}
          @useBtcpay={{@useBtcpay}}
        />
      </div>
    </article>
  </template>
}
