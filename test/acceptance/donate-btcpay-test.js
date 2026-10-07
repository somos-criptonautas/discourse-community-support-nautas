import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
// The theme bundle mounts javascripts/discourse/ at the theme root, so theme
// modules are two levels up from test/acceptance/ without the javascripts/ part.
import { resetBtcpayCaches } from "../../discourse/lib/btcpay";

const BTCPAY_METHOD = {
  name: "Bitcoin",
  description: "Donate with Bitcoin or Lightning.",
  button_text: "Donate",
  use_btcpay: true,
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
// modal it needs no auto-open timer and no click target.
const OUTLET_SETTINGS = {
  outlet_enabled: true,
  outlet_locations: "above-main-container",
  support_bar_enabled: true,
  support_bar_in_outlets: true,
  support_goal: 200,
  support_current: 10,
  support_currency: "",
  donation_methods: [BTCPAY_METHOD],
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

acceptance("Community Support | BTCPay donations", function (needs) {
  let restoreSettings;

  needs.user();
  needs.pretender(stubEndpoints);

  needs.hooks.beforeEach(function () {
    resetBtcpayCaches();
    restoreSettings = applySettings(OUTLET_SETTINGS);
  });

  needs.hooks.afterEach(function () {
    restoreSettings();
    resetBtcpayCaches();
    delete window.btcpay;
  });

  test("a BTCPay method renders an amount field instead of an outbound link", async function (assert) {
    await visit("/");

    assert.dom(".donate-option-card__btcpay input").exists();
    assert.dom(".donate-option-card__content a.btn-primary").doesNotExist();
    // The plugin's currency wins over the theme's display-only setting.
    assert.dom(".donate-option-card__amount-currency").hasText("EUR");
  });

  test("the support bar uses the live total instead of support_current", async function (assert) {
    await visit("/");

    assert.dom(".donate-support-bar__totals strong").hasText("120 EUR");
    assert.dom(".donate-support-bar__heading strong").hasText("60%");
  });

  test("donating opens the BTCPay modal with the invoice from the plugin", async function (assert) {
    const shown = [];
    window.btcpay = {
      showInvoice: (id) => shown.push(id),
      onModalWillLeave: () => {},
    };

    await visit("/");
    await fillIn(".donate-option-card__btcpay input", "12.50");
    await click(".donate-option-card__btcpay button[type='submit']");

    assert.deepEqual(shown, ["INV1"], "the server-created invoice is shown");
    // Guard against a second click stacking a second overlay.
    assert
      .dom(".donate-option-card__btcpay button[type='submit']")
      .isDisabled();
  });
});

acceptance(
  "Community Support | BTCPay donations (anonymous)",
  function (needs) {
    let restoreSettings;

    needs.pretender(stubEndpoints);

    needs.hooks.beforeEach(function () {
      resetBtcpayCaches();
      restoreSettings = applySettings(OUTLET_SETTINGS);
    });

    needs.hooks.afterEach(function () {
      restoreSettings();
      resetBtcpayCaches();
    });

    test("anonymous visitors get a log-in button", async function (assert) {
      await visit("/");

      // /btcpay/donate.json answers 403 for them, so never show the form.
      assert.dom(".donate-option-card__btcpay").doesNotExist();
      assert.dom(".donate-option-card__content button.btn-primary").exists();
    });
  }
);
