const {
  createPaymentService,
  handlePaymentSucceededService,
  handlePaymentFailedService,
  confirmPaymentService
} = require("../services/payment.service");

const { stripe, isSimulator } = require("../config/stripe");

const WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET;

// ========================
// CREATE PAYMENT
// POST /payments  { orderId, method }
// ========================
const createPayment = async (req, res) => {
  try {
    const { orderId, method } = req.body;

    const result = await createPaymentService(
      req.user._id,
      orderId,
      method
    );

    res.status(201).json({
      message:
        method === "stripe"
          ? "Payment intent created"
          : "Cash order confirmed",
      ...result
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// ========================
// STRIPE WEBHOOK
// POST /payments/webhook   (raw body, no auth — called by Stripe)
// ========================
const stripeWebhook = async (req, res) => {
  let event;

  try {
    const signature = req.headers["stripe-signature"];
    event = stripe.webhooks.constructEvent(
      req.body, // raw Buffer
      signature,
      WEBHOOK_SECRET
    );
  } catch (error) {
    // Signature verification failed -> reject.
    return res.status(400).json({ message: `Webhook Error: ${error.message}` });
  }

  try {
    switch (event.type) {
      case "payment_intent.succeeded":
        await handlePaymentSucceededService(event.data.object.id);
        break;

      case "payment_intent.payment_failed":
        await handlePaymentFailedService(
          event.data.object.id,
          event.data.object.last_payment_error?.message
        );
        break;

      default:
        // Unhandled event types are acknowledged so Stripe stops retrying.
        break;
    }

    // Always 200 once handled so Stripe doesn't keep retrying.
    return res.status(200).json({ received: true });
  } catch (error) {
    // Returning 500 tells Stripe to retry later.
    return res.status(500).json({ message: error.message });
  }
};

// ========================
// CONFIRM PAYMENT (fallback to webhook)
// POST /payments/:paymentIntentId/confirm
// ========================
const confirmPayment = async (req, res) => {
  try {
    const payment = await confirmPaymentService(
      req.user._id,
      req.params.paymentIntentId
    );

    res.status(200).json({
      message: "Payment reconciled",
      payment
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// ========================
// SIMULATE PAYMENT (simulator mode only)
// POST /payments/simulate  { paymentIntentId, paymentMethod }
//
// Mimics the customer confirming a card on the frontend. We confirm the
// PaymentIntent, build the matching event, sign it the way Stripe would, and
// POST it to our own /payments/webhook — so the real webhook path (including
// signature verification) runs end-to-end without a Stripe account or CLI.
// ========================
const simulatePayment = async (req, res) => {
  if (!isSimulator) {
    return res.status(400).json({
      message: "Simulation is only available in simulator mode"
    });
  }

  try {
    const { paymentIntentId, paymentMethod } = req.body;

    const intent = await stripe.paymentIntents.confirm(paymentIntentId, {
      payment_method: paymentMethod || "pm_card_visa"
    });

    const eventType =
      intent.status === "succeeded"
        ? "payment_intent.succeeded"
        : "payment_intent.payment_failed";

    const payload = JSON.stringify({
      id: `evt_${Date.now()}`,
      type: eventType,
      data: { object: intent }
    });

    const signature = stripe.webhooks.generateTestHeader(
      payload,
      WEBHOOK_SECRET
    );

    const port = process.env.PORT || 5000;
    const webhookResponse = await fetch(
      `http://localhost:${port}/payments/webhook`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "stripe-signature": signature
        },
        body: payload
      }
    );

    res.status(200).json({
      message: "Simulated payment dispatched to webhook",
      paymentIntentStatus: intent.status,
      webhookStatus: webhookResponse.status
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = {
  createPayment,
  stripeWebhook,
  confirmPayment,
  simulatePayment
};
