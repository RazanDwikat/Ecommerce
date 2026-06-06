/**
 * Local Stripe simulator.
 *
 * Mimics the parts of the real Stripe Node SDK that this project uses, so the
 * rest of the codebase (services/controllers) talks to the exact same interface
 * whether we run against the simulator or the real Stripe API. Switching to the
 * real Stripe is then just `STRIPE_MODE=real` + a real `sk_test_...` key, with
 * no code changes.
 *
 * Implemented surface:
 *   - paymentIntents.create / retrieve / confirm
 *   - webhooks.constructEvent  (real HMAC-SHA256 signature verification)
 *   - webhooks.generateTestHeader  (simulator-only helper to sign events)
 */
const crypto = require("crypto");

// In-memory store of PaymentIntents. In real Stripe these live on Stripe's
// servers; here we keep them in a Map for the lifetime of the process.
const intents = new Map();

const genId = (prefix) =>
  `${prefix}_${crypto.randomBytes(12).toString("hex")}`;

const paymentIntents = {
  // stripe.paymentIntents.create({ amount, currency, metadata })
  async create({ amount, currency, metadata }) {
    const id = genId("pi");
    const intent = {
      id,
      object: "payment_intent",
      amount,
      currency: currency || "usd",
      metadata: metadata || {},
      status: "requires_payment_method",
      client_secret: `${id}_secret_${crypto.randomBytes(8).toString("hex")}`,
      last_payment_error: null,
      created: Math.floor(Date.now() / 1000)
    };
    intents.set(id, intent);
    return intent;
  },

  // stripe.paymentIntents.retrieve(id)
  async retrieve(id) {
    const intent = intents.get(id);
    if (!intent) {
      const err = new Error(`No such payment_intent: ${id}`);
      err.statusCode = 404;
      throw err;
    }
    return intent;
  },

  // stripe.paymentIntents.confirm(id, { payment_method })
  // Outcome mimics Stripe test cards: any "decline" token fails, else succeeds.
  async confirm(id, { payment_method } = {}) {
    const intent = intents.get(id);
    if (!intent) {
      const err = new Error(`No such payment_intent: ${id}`);
      err.statusCode = 404;
      throw err;
    }

    const pm = (payment_method || "pm_card_visa").toLowerCase();
    const declined = pm.includes("decline") || pm.includes("fail");

    if (declined) {
      intent.status = "requires_payment_method";
      intent.last_payment_error = {
        code: "card_declined",
        message: "Your card was declined."
      };
    } else {
      intent.status = "succeeded";
      intent.last_payment_error = null;
    }

    intents.set(id, intent);
    return intent;
  }
};

const computeSignature = (payload, secret, timestamp) =>
  crypto
    .createHmac("sha256", secret)
    .update(`${timestamp}.${payload}`, "utf8")
    .digest("hex");

const webhooks = {
  // Same contract as stripe.webhooks.constructEvent: verify the signature
  // header against the raw body, throw on mismatch, return the parsed event.
  constructEvent(rawBody, signatureHeader, secret) {
    const payload = Buffer.isBuffer(rawBody)
      ? rawBody.toString("utf8")
      : String(rawBody);

    const parts = {};
    String(signatureHeader || "")
      .split(",")
      .forEach((part) => {
        const [key, value] = part.split("=");
        parts[key] = value;
      });

    const { t: timestamp, v1: provided } = parts;
    if (!timestamp || !provided) {
      throw new Error("Webhook signature missing required fields");
    }

    const expected = computeSignature(payload, secret, timestamp);
    const expectedBuf = Buffer.from(expected);
    const providedBuf = Buffer.from(provided);

    if (
      expectedBuf.length !== providedBuf.length ||
      !crypto.timingSafeEqual(expectedBuf, providedBuf)
    ) {
      throw new Error("Webhook signature verification failed");
    }

    return JSON.parse(payload);
  },

  // Simulator-only: sign an event the way Stripe would, so the /simulate
  // endpoint can POST a properly signed event to our own /webhook endpoint.
  generateTestHeader(payload, secret) {
    const timestamp = Math.floor(Date.now() / 1000);
    const signature = computeSignature(payload, secret, timestamp);
    return `t=${timestamp},v1=${signature}`;
  }
};

module.exports = { paymentIntents, webhooks };
