import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import DiscourseURL from "discourse/lib/url";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import sinon from "sinon";
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

const STRIPE_METHOD = {
  name: "Card",
  description: "Pay by card through Stripe.",
  button_text: "Donate by card",
  url: "https://buy.stripe.com/test_abc123",
  use_stripe: true,
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
  donation_methods: [BTCPAY_METHOD, LINK_METHOD, STRIPE_METHOD],
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
      .dom(".donate-modal__hero-action .donate-option-card__amount-form input")
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

    assert.dom(".donate-modal__grid .donate-option-card").exists({ count: 2 });
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

  test("the progress sits inside the box", async function (assert) {
    await visit("/");

    assert.dom(".donate-modal__hero .donate-support-bar").exists();
    assert.dom(".donate-support-bar").exists({ count: 1 }, "and only there");
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
      ".donate-modal__hero-action .donate-option-card__amount-form input",
      "12.50"
    );
    await click(
      ".donate-modal__hero-action .donate-option-card__amount-form button[type='submit']"
    );

    assert.deepEqual(shown, ["INV1"], "the server-created invoice is shown");
    // Guard against a second click stacking a second overlay.
    assert
      .dom(
        ".donate-modal__hero-action .donate-option-card__amount-form button[type='submit']"
      )
      .isDisabled();
  });

  test("a Stripe method opens its payment link with the amount prefilled", async function (assert) {
    const opened = [];
    const originalOpen = window.open;
    window.open = (url, target, features) =>
      opened.push({ url, target, features });

    try {
      await visit("/");
      // BTCPay is featured and lives in the box, so the only amount form in
      // the list is the Stripe one.
      await fillIn(
        ".donate-modal__grid .donate-option-card__amount-form input",
        "10"
      );
      await click(
        ".donate-modal__grid .donate-option-card__amount-form button[type='submit']"
      );
    } finally {
      window.open = originalOpen;
    }

    assert.strictEqual(opened.length, 1, "exactly one tab is opened");
    const url = new URL(opened[0].url);
    assert.strictEqual(url.origin + url.pathname, STRIPE_METHOD.url);
    assert.strictEqual(url.searchParams.get("prefilled_amount"), "1000");
    assert.true(
      /^discourse-\d+$/.test(url.searchParams.get("client_reference_id")),
      "logged-in donors are tagged with a Stripe-safe reference"
    );
    assert.strictEqual(opened[0].target, "_blank");
  });

  test("rows keep one template whatever fields a method fills in", async function (assert) {
    await visit("/");

    assert
      .dom(".donate-modal__grid .donate-option-card__body")
      .exists({ count: 2 });
    assert
      .dom(".donate-modal__grid .donate-option-card__action")
      .exists({ count: 2 });
  });
});

acceptance("Community Support | sidebar view", function (needs) {
  needs.user();
  setup(needs, { outlet_view: "sidebar" });

  test("discourse-right-sidebar-blocks can resolve the block by name", function (assert) {
    // That component looks blocks up with resolveRegistration and nothing
    // else, so this is the whole integration contract.
    assert.ok(
      this.owner.resolveRegistration("component:donate-sidebar-block"),
      "component:donate-sidebar-block resolves"
    );
  });

  test("the sidebar block is the compact variant, not the full box", async function (assert) {
    await visit("/");

    assert.dom(".donate-component.--view-sidebar .donate-sidebar").exists();
    assert.dom(".donate-sidebar__head strong").exists("it has a short title");
    assert.dom(".donate-sidebar .donate-support-bar__track").exists();
    assert
      .dom(".donate-sidebar .donate-option-card__amount-form input")
      .exists();
    assert
      .dom(".donate-modal__hero")
      .doesNotExist("no hero copy in the sidebar");
    assert
      .dom(".donate-modal__grid")
      .doesNotExist("no method grid in the sidebar");
  });
});

acceptance("Community Support | progress view", function (needs) {
  needs.user();
  setup(needs, { outlet_view: "progress" });

  test("views that hide the box keep the bar on its own", async function (assert) {
    await visit("/");

    assert.dom(".donate-support-bar").exists();
    assert.dom(".donate-modal__hero .donate-support-bar").doesNotExist();
  });
});

acceptance("Community Support | url_must_contain", function (needs) {
  needs.user();
  setup(needs, { display_on_homepage: false, url_must_contain: "/faq" });

  test("a value matches anywhere in the address, not only exactly", async function (assert) {
    settings.url_must_contain = "atest";
    await visit("/latest");

    assert.dom(".donate-component").exists("/latest contains 'atest'");
  });

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
      .dom(".donate-modal__hero-action .donate-option-card__amount-form")
      .doesNotExist();
    assert.dom(".donate-modal__hero-action button.btn-primary").exists();
  });
});

acceptance("Community Support | card through BTCPay", function (needs) {
  needs.user();
  needs.settings({
    btcpay_card_payments: true,
    btcpay_donations_enabled: true,
  });

  const requests = [];

  needs.pretender((server, helper) => {
    server.get("/btcpay/donations.json", () => helper.response(DONATIONS));
    server.post("/btcpay/donate.json", (request) => {
      requests.push(new URLSearchParams(request.requestBody));
      return helper.response({
        invoice_id: "INV2",
        checkout_url: "https://btcpay.example.invalid/i/INV2/STRIPE",
        modal_url: null,
      });
    });
  });

  let restoreSettings;

  needs.hooks.beforeEach(function () {
    requests.length = 0;
    resetBtcpayCaches();
    restoreSettings = applySettings(OUTLET_SETTINGS);
  });

  needs.hooks.afterEach(function () {
    restoreSettings();
    resetBtcpayCaches();
  });

  test("a member's card donation goes through BTCPay, not the Payment Link", async function (assert) {
    const redirect = sinon.stub(DiscourseURL, "redirectTo");
    const opened = [];
    const originalOpen = window.open;
    window.open = (url) => opened.push(url);

    try {
      await visit("/");
      await fillIn(
        ".donate-modal__grid .donate-option-card__amount-form input",
        "10"
      );
      await click(
        ".donate-modal__grid .donate-option-card__amount-form button[type='submit']"
      );
    } finally {
      window.open = originalOpen;
    }

    assert.strictEqual(requests.length, 1, "the plugin creates the invoice");
    assert.strictEqual(requests[0].get("payment_method"), "card");
    assert.strictEqual(requests[0].get("amount"), "10");
    assert.true(
      redirect.calledWith("https://btcpay.example.invalid/i/INV2/STRIPE"),
      "the invoice opens on BTCPay's Stripe page"
    );
    assert.strictEqual(opened.length, 0, "the Payment Link is not used");
  });
});
