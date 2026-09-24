import { ajax } from "discourse/lib/ajax";

// Everything BTCPay-related goes through the discourse-btcpay-subscriptions
// plugin: the theme never talks to BTCPay directly and never holds an API key.
// The invoice's orderId (how a donation is attributed to a user) is generated
// server-side, so nothing here can influence it.

let donationsRequest;
let modalScriptRequest;

// Shared by the donation cards, the support bar and the supporter avatars, so
// one page render hits the endpoint once. Resolves to null when the plugin is
// missing or donations are disabled, which is what lets every caller fall back
// to its manual setting.
export function fetchDonations() {
  donationsRequest ??= ajax("/btcpay/donations.json").catch(() => null);
  return donationsRequest;
}

// BTCPay serves its own modal script; the URL comes from the plugin response.
export function loadModalScript(url) {
  // Already on the page — another card loaded it, or the site embeds it.
  if (window.btcpay?.showInvoice) {
    return Promise.resolve();
  }

  modalScriptRequest ??= new Promise((resolve, reject) => {
    const element = document.createElement("script");
    element.src = url;
    element.onload = resolve;
    element.onerror = () => reject(new Error("btcpay modal script failed"));
    document.head.appendChild(element);
  });

  return modalScriptRequest;
}

// Tests run several scenarios against one module instance; production code
// never calls this.
export function resetBtcpayCaches() {
  donationsRequest = null;
  modalScriptRequest = null;
}
