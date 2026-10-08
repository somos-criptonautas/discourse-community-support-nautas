import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";
import DonateMethodAction from "./donate-method-action";

// One row in the methods list. Every row shares a single three-column
// template — icon, text, action — so no combination of filled-in fields can
// push a row out of line with its neighbours.
export default class DonateOptionCard extends Component {
  get fallbackIcon() {
    return settings.support_icon || "heart";
  }

  // Owner and provider ride on the name line as metadata instead of taking a
  // row of their own, which is what used to shift the description down.
  get meta() {
    return [this.args.owner, this.args.provider].filter(Boolean).join(" · ");
  }

  <template>
    <article class="donate-option-card" role="listitem">
      <div class="donate-option-card__icon" aria-hidden="true">
        {{#if @icon}}
          <img class="donate-option-card__img" src={{@icon}} alt="" />
        {{else}}
          <span class="donate-option-card__fallback-icon">{{icon
              this.fallbackIcon
            }}</span>
        {{/if}}
      </div>

      <div class="donate-option-card__body">
        <h3>
          {{@name}}
          {{#if this.meta}}
            <span class="donate-option-card__meta">· {{this.meta}}</span>
          {{/if}}
        </h3>
        <p>{{@description}}</p>

        {{! Rendered on its own so a copyable IBAN or address sits in the text
            column, leaving the action column for the button. }}
        {{#if @copyValue}}
          <DonateMethodAction
            @copyLabel={{@copyLabel}}
            @copyValue={{@copyValue}}
          />
        {{/if}}
      </div>

      <div class="donate-option-card__action">
        <DonateMethodAction
          @buttonText={{@buttonText}}
          @url={{@url}}
          @useBtcpay={{@useBtcpay}}
          @useStripe={{@useStripe}}
        />
      </div>
    </article>
  </template>
}
