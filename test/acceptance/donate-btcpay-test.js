import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
// The theme bundle mounts javascripts/discourse/ at the theme root, so theme
// modules are two levels up from test/acceptance/ without the javascripts/ part.
import { resetBtcpayCaches } from "../../discourse/lib/btcpay";

// Featured: its amount field and button are what the box shows on the right.
const BTCPAY_METHOD = {
  featured: true,
  name: "Bitcoin",
  description: "Donate with Bitcoin or Lightning.",
  button_text: "Donate",
  use_btcpay: true,
  translations: [],
};

const LINK_METHOD = {
  name: "PayPal",
  description: "Support via PayPal.",
  button_text: "Open PayPal",
  url: "https://paypal.me/example",
  translations: [],
};

const DONATIONS = {
  currency: "EUR",
  total: 120,
  count: 3,
  supporters: [],
};

const INVOICE = {
  invoice_id: "INV1",
  modal_url: "https://btcpay.example.invalid/modal/btcpay.js",
  checkout_url: "https://btcpay.example.invalid/i/INV1",
};

// The outlet is the cheapest way to get the donation UI on screen: unlike the
// modal it needs no click target.
const OUTLET_SETTINGS = {
  outlet_enabled: true,
  outlet_locations: "above-main-container",
  outlet_view: "full",
  show_for_anon: true,
  display_on_homepage: true,
  url_must_contain: "*",
  // A core icon: ph-dt-hand-heart needs the Phosphor component installed.
  support_icon: "heart",
  support_bar_enabled: true,
  support_bar_in_outlets: true,
  support_goal: 200,
  support_current: 10,
  support_currency: "",
  donation_methods: [BTCPAY_METHOD, LINK_METHOD],
};

function applySettings(overrides) {
  const previous = {};

  for (const [key, value] of Object.entries(overrides)) {
    previous[key] = settings[key];
    settings[key] = value;
  }

  return () => Object.assign(settings, previous);
}

function stubEndpoints(server, helper) {
  server.get("/btcpay/donations.json", () => helper.response(DONATIONS));
  server.post("/btcpay/donate.json", () => helper.response(INVOICE));
}

function setup(needs, overrides = {}) {
  let restoreSettings;

  needs.pretender(stubEndpoints);

  needs.hooks.beforeEach(function () {
    resetBtcpayCaches();
    restoreSettings = applySettings({ ...OUTLET_SETTINGS, ...overrides });
  });

  needs.hooks.afterEach(function () {
    restoreSettings();
    resetBtcpayCaches();
    delete window.btcpay;
  });
}

acceptance("Community Support | donation box", function (needs) {
  needs.user();
  setup(needs);

  test("the featured method's amount field sits inside the box", async function (assert) {
    await visit("/");

    assert
      .dom(".donate-modal__hero-action .donate-option-card__btcpay input")
      .exists();
    assert
      .dom(".donate-modal__hero-action a.btn-primary")
      .doesNotExist("a BTCPay method never falls back to an outbound link");
    // The plugin's currency wins over the theme's display-only setting.
    assert
      .dom(".donate-modal__hero-action .donate-option-card__amount-currency")
      .hasText("EUR");
  });

  test("non-featured methods stay in the grid below", async function (assert) {
    await visit("/");

    assert.dom(".donate-modal__grid .donate-option-card").exists({ count: 1 });
    assert.dom(".donate-modal__grid a.btn-primary").hasText("Open PayPal");
  });

  test("the removed chrome is gone", async function (assert) {
    await visit("/");

    assert.dom(".donate-modal__methods-heading").doesNotExist();
    assert.dom(".donate-modal__methods-count").doesNotExist();
    assert.dom(".donate-modal__closing").doesNotExist();
    assert.dom(".donate-modal__featured").doesNotExist();
    assert
      .dom(".donate-support-bar .d-icon")
      .doesNotExist("the bar carries no icon of its own");
  });

  test("the support bar reads the live total and keeps the figures together", async function (assert) {
    await visit("/");

    assert.dom(".donate-support-bar__figures strong").hasText("120 EUR");
    assert.dom(".donate-support-bar__percentage").hasText("60%");
  });

  test("donating opens the BTCPay modal with the invoice from the plugin", async function (assert) {
    const shown = [];
    window.btcpay = {
      showInvoice: (id) => shown.push(id),
      onModalWillLeave: () => {},
    };

    await visit("/");
    await fillIn(
      ".donate-modal__hero-action .donate-option-card__btcpay input",
      "12.50"
    );
    await click(
      ".donate-modal__hero-action .donate-option-card__btcpay button[type='submit']"
    );

    assert.deepEqual(shown, ["INV1"], "the server-created invoice is shown");
    // Guard against a second click stacking a second overlay.
    assert
      .dom(
        ".donate-modal__hero-action .donate-option-card__btcpay button[type='submit']"
      )
      .isDisabled();
  });
});

acceptance("Community Support | sidebar view", function (needs) {
  needs.user();
  setup(needs, { outlet_view: "sidebar" });

  test("the sidebar block is the compact variant, not the full box", async function (assert) {
    await visit("/");

    assert.dom(".donate-component.--view-sidebar .donate-sidebar").exists();
    assert.dom(".donate-sidebar__head strong").exists("it has a short title");
    assert.dom(".donate-sidebar .donate-support-bar__track").exists();
    assert.dom(".donate-sidebar .donate-option-card__btcpay input").exists();
    assert
      .dom(".donate-modal__hero")
      .doesNotExist("no hero copy in the sidebar");
    assert
      .dom(".donate-modal__grid")
      .doesNotExist("no method grid in the sidebar");
  });
});

acceptance("Community Support | url_must_contain", function (needs) {
  needs.user();
  setup(needs, { display_on_homepage: false, url_must_contain: "/faq" });

  test("a non-matching route renders nothing at all", async function (assert) {
    await visit("/");

    assert
      .dom(".donate-component")
      .doesNotExist("the outlet honours the route setting, not just the modal");
  });
});

acceptance("Community Support | anonymous visitors", function (needs) {
  setup(needs);

  test("anonymous visitors get a log-in button", async function (assert) {
    await visit("/");

    // /btcpay/donate.json answers 403 for them, so never show the form.
    assert
      .dom(".donate-modal__hero-action .donate-option-card__btcpay")
      .doesNotExist();
    assert.dom(".donate-modal__hero-action button.btn-primary").exists();
  });
});
