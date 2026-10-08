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

- Manual `#donate` trigger — any link with that href opens the modal
- Visibility controls for members/anonymous users, trust level, routes and excluded groups
- Excluded groups hide plugin outlet widgets and generic embeds, while contextual `[wrap=donate]` blocks and the `#donate` link remain available
- Donation methods with logos, links and copyable values (IBAN, handle, address…)
- The featured method's amount field and button sit inside the support box itself
- On-site BTCPay donations, with an amount field in place of the outbound link
- Card donations through a Stripe Payment Link, with the amount prefilled — no secret key in the theme
- Per-method translations using the Discourse locale list
- Configurable hero highlights, with per-item translations from the same locale list
- Support goal and progress bar, fed either by a manual setting or by live BTCPay totals
- One-time, monthly and yearly goal periods
- Supporter avatars, from a manual list, from groups, and from real BTCPay donors
- Classic, Minimal and Modern designs
- Full, Compact, Minimal, Progress and Sidebar presentation views
- A block for the core team's [Right Sidebar Blocks](https://github.com/discourse/discourse-right-sidebar-blocks) component
- Post wrappers via `[wrap=donate*]`
- Generic HTML embed for Discourse Ads and other HTML-capable placements
- Configurable plugin outlet rendering through `renderInOutlet`
- Sized by its own width through container queries, so it fits a sidebar, a post or a modal alike; reduced-motion support
- Accessible progress semantics and keyboard-friendly copy controls

## Donation methods

Methods are configured in the `donation_methods` objects setting. One method can be marked `featured`, which puts its amount field and button inside the support box; the rest are listed below it.

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
| `featured` | Use this method for the amount field and button inside the box |
| `name`, `description`, `button_text` | Card copy (required) |
| `url` | Outbound support URL, or the Stripe Payment Link when `use_stripe` is on. Ignored when `use_btcpay` is on |
| `use_btcpay` | Take the donation on-site through the BTCPay plugin |
| `use_stripe` | Treat `url` as a Stripe Payment Link and prefill it with the entered amount |
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

**Which payment methods BTCPay offers is not set here.** The invoice lists whatever is enabled on your BTCPay *store* — on-chain BTC, Lightning, Monero and so on. BTCPay Server does not process cards by itself; for cards, add a Stripe method alongside it — see below for the route that credits them.

## Stripe donations

Stripe donations use a [Payment Link](https://docs.stripe.com/payment-links), which needs no secret key — the only way Stripe can live in a theme component.

1. In the Stripe dashboard, create a Payment Link for a product with **Customers choose what to pay**. Optionally set a preset, a minimum and a maximum.
2. Add a method with that link as `url` and `use_stripe` on:

```yaml
donation_methods:
  - name: "Card"
    description: "Pay by card or wallet."
    button_text: "Donate by card"
    url: "https://buy.stripe.com/…"
    use_stripe: true
```

The method shows the same amount field as BTCPay. Submitting it opens the link in a new tab with:

- `prefilled_amount` — the entered amount in the currency's smallest unit (10 EUR becomes `1000`; zero-decimal currencies such as JPY are not multiplied). The currency comes from `support_currency`. The donor can still change the amount on Stripe's page, and Stripe enforces the link's own minimum and maximum.
- `client_reference_id=discourse-<user id>` for logged-in donors, so donations can be matched to forum accounts in the Stripe dashboard. The numeric id is used because Stripe silently drops values outside `A-Z a-z 0-9 _ -`, and usernames may contain dots.

Cards — and Apple Pay, Google Pay or Link, if enabled on the payment link — are offered on Stripe's page. Unlike BTCPay, the form is shown to anonymous visitors too: Stripe needs no forum account.

Two deliberate omissions. The donor's email is **not** prefilled, because it would travel in the URL and end up in browser history and logs. And Stripe donations are **not** counted in the support bar: the reference above is set by the browser, which is fine for a label in the Stripe dashboard but not for crediting anyone. Counting them would need a server piece that receives Stripe's `checkout.session.completed` webhook, the same way the BTCPay plugin generates its order id server-side.

If both `use_btcpay` and `use_stripe` are set on one method, BTCPay wins.

### Credited card donations, through BTCPay

If the BTCPay store has the [Stripe plugin](https://plugin-builder.btcpayserver.org/public/plugins/stripe-payments) and the BTCPay subscriptions plugin has `btcpay_card_payments` on, a **logged-in** member's card donation skips the Payment Link. The `use_stripe` method then asks the plugin for a donation invoice with `payment_method: card`, and BTCPay opens it on its Stripe page.

That is the same invoice and the same webhook as a crypto donation, so card donations count in the support bar and the supporter list, and earn the donor badge and points. That fixes the omission described above. The amount is charged in the plugin's `btcpay_donation_currency`, as with BTCPay.

Visitors without an account still get the Payment Link, since the plugin can only attribute a donation to an account. A `url` is then optional on the method: without one, anonymous visitors see no card option.

## Layout

The default placement is one box followed by the progress bar and then the remaining methods:

```
┌─ support box ──────────────────────────────────────┐
│ ♥  Help keep our community running                 │
│    Community-funded projects rely   ┌───────┐      │
│    on people who find them useful.  │ 10 EUR│      │
│    [no ads] [community funded]      └───────┘      │
│                                     [  Donate  ]   │
│ ─────────────────────────────────────────────────  │
│ 120 EUR of 200 EUR · Monthly                  60%  │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
└────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────┐
│ ⬡  PayPal · paypal.me               [ Open PayPal ]│
│    Support the community via PayPal.               │
├────────────────────────────────────────────────────┤
│ ⬡  Card · Stripe          [ 10 EUR ][ Donate card ]│
│    Pay by card or wallet.                          │
├────────────────────────────────────────────────────┤
│ ⬡  Bank transfer · Caja Rural                      │
│    ┌ IBAN  ES00 0000 0000 0000  ⧉ ┐               │
└────────────────────────────────────────────────────┘
```

The box is the hero and the featured method in one: copy on the left, that method's amount field and button on the right. Every other method is a row in the list below. All rows share one template — icon, text, action — so a method with an owner, a provider or a copyable value lines up exactly like one without. Owner and provider ride on the name line; a copyable value sits in the text column.

The layout responds to its own width rather than the window's (container queries). Below about 36rem the box's action moves under its copy and each row's action moves under its text — so it reads correctly in a narrow sidebar column on a wide screen, where viewport breakpoints would still say "desktop".

In standalone placements the box, the bar and the list are three rounded surfaces with shared edges. In the modal they stay flush, because the modal already clips its own corners. The icon is set by `support_icon`; it is the only icon in the layout.

## Support bar

The support bar can be enabled globally and shown independently in the modal, post embeds, plugin outlets and generic embeds. It supports inline, stacked and compact layouts.

The figures read as one line — raised total, what it is measured against, the period, and the percentage — so nothing is separated across the width of the bar. `support_label` is used as the bar's accessible name rather than a visible heading.

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

Outlet widgets and generic embeds both honour `url_must_contain`, `display_on_homepage`, `show_for_members`, `show_for_anon`, `trust_level` and `excluded_groups`, re-checked on every navigation. Post embeds deliberately skip those checks: a `[wrap=donate]` block was placed on that page on purpose by whoever wrote the post.

Examples: `above-main-container`, `before-topic-list`, `after-topic-list`, `topic-list-bottom`, `below-site-header`, `main-outlet-bottom`, `before-main-outlet`. Exact availability depends on the Discourse version and the installed themes and components.

The outlet view and design can be configured independently from the global defaults.

## Right sidebar

The core team's [Right Sidebar Blocks](https://github.com/discourse/discourse-right-sidebar-blocks) component renders a column of blocks beside topic lists. This component ships one for it, `donate-sidebar-block`, which shows the `sidebar` view.

Install Right Sidebar Blocks, then add the block to its `blocks` setting:

```json
[{ "name": "donate-sidebar-block" }]
```

Order it among the other blocks there. Where the column appears is Right Sidebar Blocks' business — its `show_in_routes` setting, topic-list routes only, never on mobile. This component only adds who may see it — `show_for_members`, `show_for_anon`, `trust_level`, `excluded_groups`. It does not apply `url_must_contain` or `display_on_homepage` here: the route is Right Sidebar Blocks' to decide, and checking both hid the block on pages where it had been placed. The support bar is shown when `support_bar_in_outlets` is on.

Right Sidebar Blocks looks blocks up by name through the resolver, which takes the first module whose path ends in `components/<name>`. That is why the name is long and specific; keep it that way.

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
- `sidebar` — a purpose-built compact block: icon, short title, slim bar, amount field and button. Not the full box scaled down; it drops the hero copy and the method list, because neither fits. Used by the [right sidebar block](#right-sidebar), and selectable for any outlet.

Design and view are intentionally orthogonal, so every view works with every design.

## Icons

`support_icon` sets the one icon in the layout — the box, the sidebar block, and the fallback when a method has no uploaded logo. It defaults to `ph-dt-hand-heart`, which needs the [Phosphor Duotone icons component](https://github.com/somos-criptonautas/discourse-phosphor-duotone-icons-nautas) installed; set it to `heart` or any other core icon name if you are not using that component.

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

MIT. See [LICENSE](LICENSE).

Text of this README under [CC BY-NC-SA 4.0](CC-BY-NC-SA-4.0.txt).
