/**
 * Stripe provider selector.
 *
 * Returns the real Stripe SDK when STRIPE_MODE=real, otherwise the local
 * simulator. Both expose the same interface, so the rest of the app never
 * needs to know which one is active.
 */
const stripeMode = process.env.STRIPE_MODE || "simulator";

let stripe;

if (stripeMode === "real") {
  // Lazily required so simulator users don't depend on a valid key at boot.
  stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
} else {
  stripe = require("../lib/stripeSimulator");
}

const isSimulator = stripeMode !== "real";

module.exports = { stripe, stripeMode, isSimulator };
