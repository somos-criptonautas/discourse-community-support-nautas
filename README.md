# Community Support

A provider-agnostic Discourse Theme Component for community support, donations and fundraising widgets. It is designed to use the same presentation system in modals, posts, plugin outlets, and HTML-based placements such as Discourse Ads.

## Features

### Supporter avatars

The support bar can optionally show a configurable number of small supporter avatars. Supporters are added manually in the `supporters` object setting using their Discourse username. The component resolves their public profile and avatar automatically. When more supporters exist than the configured visible avatar count, a `+N` DMenu opens a complete supporter list.

You can also enable supporter contribution amounts in that list with `show_supporter_amounts`.

- Optional automatic support modal with cookie-based dismissal
- Manual `#donate` trigger
- Excluded groups hide automatic modal triggers, plugin outlet widgets and generic embeds, while contextual `[wrap=donate]` blocks remain available
- Visibility controls for members/anonymous users, trust level, routes and excluded groups
- Donation/support methods with icons, links and copyable values
- Per-method translations using the Discourse locale list
- Configurable hero highlights with per-item translations using the same supported Discourse locale list as donation methods
- Configurable support goal and progress bar
- One-time, monthly and yearly goal periods
- Classic, Minimal and Modern designs
- Full, Compact, Minimal and Progress presentation views
- Post wrappers via `[wrap=donate*]`
- Generic HTML embed for Discourse Ads and other HTML-capable placements
- Configurable plugin outlet rendering through `renderInOutlet`
- Responsive layout and reduced-motion support
- Accessible progress semantics and keyboard-friendly copy controls

## Post embeds

Enable `enable_post_embed`, then use any of the following wrappers in a post:

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

Use the stable embed marker anywhere the Theme Component can decorate cooked HTML:

```html
<div data-donation-widget="support"></div>
```

The marker can optionally override the global presentation:

```html
<div
  data-donation-widget="support"
  data-view="compact"
  data-design="minimal"
></div>
```

The HTML stays stable while the Theme Component owns all markup and CSS. This makes the embed suitable for Discourse Ads HTML placements.

## Discourse Ads

Create an HTML ad containing the generic embed marker and place it in the desired Ads outlet. No donation-specific CSS is required in the ad itself.

## Plugin outlets

Enable `outlet_enabled` and provide one or more outlet names in `outlet_locations`, separated by `|`. The component uses Discourse's `api.renderInOutlet()` API to render the widget.

The outlet view and design can be configured independently from the global post defaults.

## Views and designs

Design controls the visual language:

- `classic` — balanced community-style cards
- `minimal` — low-chrome, compact presentation
- `modern` — larger type, stronger visual hierarchy and elevated cards

View controls how much content is shown:

- `full` — complete hero, featured method and method list
- `compact` — reduced chrome for tighter placements
- `minimal` — method-focused presentation
- `progress` — support goal/progress only

Design and view are intentionally orthogonal, so every view can be used with every design.

## Support bar

The support bar can be enabled globally and independently shown in the modal, post embeds, plugin outlets and generic embeds. It supports inline, stacked and compact layouts. Below the first goal it uses `tertiary-low` as the track and `tertiary` as the fill; at exactly 100% (and every exact 200%, 300%, etc. milestone) the track and fill use `success`. Between milestones, the track uses `success-low` and the current cycle uses `success` as its fill, while the displayed percentage continues to show the real total (for example, 125% or 220%).

## Example donation method

```yaml
donation_methods:
  - featured: true
    name: "PayPal"
    description: "Support the community via PayPal."
    button_text: "Support via PayPal"
    url: "https://paypal.me/example"
```

## Example Ads embed

```html
<div data-donation-widget="support" data-view="compact" data-design="minimal"></div>
```

## Suggested outlet locations

The `outlet_locations` setting accepts `|`-separated outlet names. Examples include `above-main-container`, `before-topic-list`, `after-topic-list`, `topic-list-bottom`, `below-site-header`, `main-outlet-bottom` and `before-main-outlet`. Exact availability depends on the Discourse version and installed themes/components.

## License

MIT
