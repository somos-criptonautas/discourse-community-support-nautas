// Stripe Payment Links need no secret key, which is the only way Stripe can
// live in a theme component. A pay-what-you-want link accepts the amount as a
// URL parameter, so the card method reuses the same amount field as BTCPay.
//
// https://docs.stripe.com/payment-links/customize — prefilled_amount
// https://docs.stripe.com/payment-links/url-parameters — client_reference_id

// Payment Links take the amount in the currency's smallest unit (20.00 EUR is
// 2000), and that unit differs per currency (JPY has none). Intl already knows
// each currency's digits; with no or an unknown currency, assume cents.
function minorUnitDigits(currency) {
  try {
    return new Intl.NumberFormat("en", {
      style: "currency",
      currency,
    }).resolvedOptions().maximumFractionDigits;
  } catch {
    return 2;
  }
}

export function stripeDonationUrl(link, { amount, currency, userId } = {}) {
  let url;
  try {
    url = new URL(link);
  } catch {
    return link;
  }

  const value = Number(amount);
  if (Number.isFinite(value) && value > 0) {
    const minor = Math.round(value * 10 ** minorUnitDigits(currency));
    url.searchParams.set("prefilled_amount", String(minor));
  }

  // Lets the donation be matched to a forum account in the Stripe dashboard.
  // The numeric id, not the username: Stripe drops any value outside
  // [A-Za-z0-9_-], and usernames may contain dots. This is a label only —
  // nothing in Discourse credits it, so a browser-chosen value is harmless.
  if (userId) {
    url.searchParams.set("client_reference_id", `discourse-${userId}`);
  }

  return url.toString();
}
