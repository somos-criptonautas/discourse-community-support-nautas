# Community Support

[![Discourse Theme](https://github.com/somos-criptonautas/discourse-community-support-nautas/actions/workflows/discourse-theme.yml/badge.svg)](https://github.com/somos-criptonautas/discourse-community-support-nautas/actions/workflows/discourse-theme.yml)

**ENGLISH** | [ESPAÑOL](README.es.md)

A provider-agnostic Discourse theme component for community support, donations and fundraising widgets. The same presentation system is reused in modals, posts, plugin outlets and HTML placements such as Discourse Ads.

Donations are normally outbound links. With [discourse-btcpay-subscriptions](https://github.com/somos-criptonautas/discourse-btcpay-subscriptions) installed, a method can instead take the payment on-site — see [BTCPay donations](#btcpay-donations). Every BTCPay feature degrades to the previous behaviour when the plugin is absent, so the component works unchanged without it.

## Requirements

- Discourse 3.4+ — the component ships `.gjs` Glimmer components and uses the objects schema for settings
- Optional: [discourse-btcpay-subscriptions](https://github.com/somos-criptonautas/discourse-btcpay-subscriptions) for on-site donations and live totals

## Installation

Admin → Customize → Themes → Components → Install → From a git repository, then add the repository URL. For a private repository, use the SSH URL and add the deploy key Discourse shows you to the repository's *Deploy keys*.

Install it as a component and add it to the themes that should show it.

## Features

- Optional automatic support modal with cookie-based dismissal
- Manual `#donate` trigger — any link with that href opens the modal
- Visibility controls for members/anonymous users, trust level, routes and excluded groups
- Excluded groups hide automatic modal triggers, plugin outlet widgets and generic embeds, while contextual `[wrap=donate]` blocks and the `#donate` link remain available
- Donation methods with logos, links and copyable values (IBAN, handle, address…)
- On-site BTCPay donations, with an amount field in place of the outbound link
- Per-method translations using the Discourse locale list
- Configurable hero highlights, with per-item translations from the same locale list
- Support goal and progress bar, fed either by a manual setting or by live BTCPay totals
- One-time, monthly and yearly goal periods
- Supporter avatars, from a manual list, from groups, and from real BTCPay donors
- Classic, Minimal and Modern designs
- Full, Compact, Minimal and Progress presentation views
- Post wrappers via `[wrap=donate*]`
- Generic HTML embed for Discourse Ads and other HTML-capable placements
- Configurable plugin outlet rendering through `renderInOutlet`
- Responsive layout and reduced-motion support
- Accessible progress semantics and keyboard-friendly copy controls

## Donation methods

Methods are configured in the `donation_methods` objects setting. One method can be marked `featured`, which promotes it to its own section above the grid.

```yaml
donation_methods:
  - featured: true
    name: "PayPal"
    description: "Support the community via PayPal."
    button_text: "Support via PayPal"
    url: "https://paypal.me/example"
  - name: "Bank transfer"
    description: "Direct transfer, no fees."
    button_text: "Details"
    copy_label: "IBAN"
    copy_value: "ES00 0000 0000 0000 0000 0000"
```

| Field | Purpose |
| --- | --- |
| `featured` | Promote this method to the featured section |
| `name`, `description`, `button_text` | Card copy (required) |
| `url` | Outbound support URL. Ignored when `use_btcpay` is on |
| `use_btcpay` | Take the donation on-site through the BTCPay plugin |
| `icon` | Optional provider logo (upload) |
| `owner`, `provider` | Optional recipient and payment provider shown on the card |
| `copy_label`, `copy_value` | One-click copyable value, such as an IBAN or address |
| `translations` | Per-locale overrides of the text fields |

## BTCPay donations

Set `use_btcpay` on a method to collect the donation without leaving Discourse:

```yaml
donation_methods:
  - name: "Bitcoin"
    description: "Donate with Bitcoin or Lightning."
    button_text: "Donate"
    use_btcpay: true
```

The card then renders an amount field and a button instead of a link. Pressing the button:

1. posts the amount to `POST /btcpay/donate.json`, which the plugin answers with an invoice id, a modal URL and a hosted checkout URL;
2. loads BTCPay's own modal script and calls `window.btcpay.showInvoice()` with that invoice id;
3. falls back to the hosted checkout page if the script cannot load.

The button stays disabled while an invoice is being created and while the overlay is open, so a double click cannot stack two overlays. Anonymous visitors get a log-in button instead, because the endpoint only serves logged-in users. Validation errors from the plugin — an amount below the minimum, the rate limit — are shown under the field.

The theme never talks to BTCPay directly and holds no API key. The order id that attributes a donation to a Discourse user is generated server-side, so the browser cannot influence it.

The same plugin feeds two read-only pieces from `GET /btcpay/donations.json`:

- the **support bar total**, replacing the manual `support_current` setting (`support_goal` stays manual);
- the **supporter avatars**, merged with the manually configured list.

Both fall back to their manual settings when the request fails or the plugin is absent. The endpoint is requested once per page render and shared by every card, the bar and the avatar list.

The minimum donation amount, the donation currency and the rate limit are the plugin's site settings, not this component's.

## Support bar

The support bar can be enabled globally and shown independently in the modal, post embeds, plugin outlets and generic embeds. It supports inline, stacked and compact layouts.

Below the first goal it uses `tertiary-low` as the track and `tertiary` as the fill; at exactly 100% — and at every exact 200%, 300%… milestone — the track and fill use `success`. Between milestones the track uses `success-low` and the current cycle uses `success` as its fill, while the displayed percentage keeps showing the real total (for example 125% or 220%).

## Supporter avatars

The support bar can show a configurable number of small supporter avatars. Supporters come from three sources, merged in this order, with the first entry winning on a username conflict:

1. the manual `supporters` setting — a Discourse username, plus an optional amount, with profile and avatar resolved at runtime;
2. real donors reported by the BTCPay plugin, when installed;
3. members of the groups listed in `supporter_groups`, newest join first.

When more supporters exist than the visible avatar count, a `+N` menu opens the complete list. `show_supporter_amounts` adds contribution amounts to that list.

## Post embeds

Enable `enable_post_embed`, then use any of these wrappers in a post:

```markdown
[wrap=donate]
[/wrap]

[wrap=donate-compact]
[/wrap]

[wrap=donate-minimal]
[/wrap]

[wrap=donate-progress]
[/wrap]
```

The wrapper selects the view while the global `design` setting controls the visual design.

## Generic embed

Use the stable embed marker anywhere the component can decorate cooked HTML:

```html
<div data-donation-widget="support"></div>
```

The marker can override the global presentation:

```html
<div
  data-donation-widget="support"
  data-view="compact"
  data-design="minimal"
></div>
```

The HTML stays stable while the component owns all markup and CSS, which makes the embed suitable for Discourse Ads HTML placements. Create an HTML ad containing the marker and place it in the desired Ads outlet; no donation-specific CSS is required in the ad itself.

## Plugin outlets

Enable `outlet_enabled` and provide one or more outlet names in `outlet_locations`, separated by `|`. The component renders through `api.renderInOutlet()`.

Examples: `above-main-container`, `before-topic-list`, `after-topic-list`, `topic-list-bottom`, `below-site-header`, `main-outlet-bottom`, `before-main-outlet`. Exact availability depends on the Discourse version and the installed themes and components.

The outlet view and design can be configured independently from the global defaults.

## Views and designs

Design controls the visual language:

- `classic` — balanced community-style cards
- `minimal` — low-chrome, compact presentation
- `modern` — larger type, stronger hierarchy, elevated cards

View controls how much content is shown:

- `full` — complete hero, featured method and method list
- `compact` — reduced chrome for tighter placements
- `minimal` — method-focused presentation
- `progress` — support goal and progress only

Design and view are intentionally orthogonal, so every view works with every design.

## Localization

English and Spanish ship with the component; every other locale falls back to English. Method names, descriptions, button labels and hero highlights are translated per item in their own settings, not in the locale files, so admins can localize their own copy without a code change.

## Development

```bash
pnpm install
pnpm lint          # eslint, prettier, stylelint, ember-template-lint
pnpm lint:fix
```

Tests live in `test/acceptance/` and run against a real Discourse instance in CI. Pushing to `main` or opening a pull request runs [discourse/.github](https://github.com/discourse/.github)'s shared theme workflow, which lints, validates `locales/en.yml` and `.discourse-compatibility`, and runs the QUnit suite.

To run the tests locally you need a Discourse development checkout:

```bash
cd path/to/discourse
bin/rake "themes:install[/path/to/discourse-community-support-nautas]"
bin/rake "themes:qunit[name,Community Support]"
```

## License

GPL-3.0. See [LICENSE](LICENSE).

Text of this README under [CC BY-NC-SA 4.0](CC-BY-NC-SA-4.0.txt).
