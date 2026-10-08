import { module, test } from "qunit";
import { stripeDonationUrl } from "../../discourse/lib/stripe";

const LINK = "https://buy.stripe.com/test_abc123";

module("Community Support | Unit | stripeDonationUrl", function () {
  test("converts the amount to the currency's smallest unit", function (assert) {
    const url = new URL(
      stripeDonationUrl(LINK, { amount: "12.5", currency: "EUR" })
    );
    assert.strictEqual(url.searchParams.get("prefilled_amount"), "1250");
  });

  test("zero-decimal currencies are not multiplied", function (assert) {
    const url = new URL(
      stripeDonationUrl(LINK, { amount: "1000", currency: "JPY" })
    );
    assert.strictEqual(url.searchParams.get("prefilled_amount"), "1000");
  });

  test("floating point does not leak into the minor units", function (assert) {
    const url = new URL(
      stripeDonationUrl(LINK, { amount: "0.29", currency: "EUR" })
    );
    assert.strictEqual(url.searchParams.get("prefilled_amount"), "29");
  });

  test("no currency configured falls back to cents", function (assert) {
    const url = new URL(stripeDonationUrl(LINK, { amount: "5", currency: "" }));
    assert.strictEqual(url.searchParams.get("prefilled_amount"), "500");
  });

  test("an empty or invalid amount leaves the link's own preset alone", function (assert) {
    for (const amount of ["", "0", "-3", "abc", undefined]) {
      const url = new URL(stripeDonationUrl(LINK, { amount, currency: "EUR" }));
      assert.false(
        url.searchParams.has("prefilled_amount"),
        `amount ${amount}`
      );
    }
  });

  test("tags logged-in donors with a Stripe-safe reference", function (assert) {
    const url = new URL(stripeDonationUrl(LINK, { userId: 42 }));
    assert.strictEqual(
      url.searchParams.get("client_reference_id"),
      "discourse-42"
    );
  });

  test("anonymous donors are not tagged", function (assert) {
    const url = new URL(stripeDonationUrl(LINK, {}));
    assert.false(url.searchParams.has("client_reference_id"));
  });

  test("keeps the link's existing parameters", function (assert) {
    const url = new URL(
      stripeDonationUrl(`${LINK}?utm_source=forum`, {
        amount: "3",
        currency: "EUR",
      })
    );
    assert.strictEqual(url.searchParams.get("utm_source"), "forum");
    assert.strictEqual(url.searchParams.get("prefilled_amount"), "300");
  });

  test("an unparseable link is returned untouched", function (assert) {
    assert.strictEqual(
      stripeDonationUrl("not a url", { amount: "3" }),
      "not a url"
    );
  });
});
