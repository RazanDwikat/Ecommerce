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
  console.log('[PAYMENT] ===== CREATE PAYMENT REQUEST =====');
  console.log('[PAYMENT] Method:', req.body.method);
  console.log('[PAYMENT] Order ID:', req.body.orderId);
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
  console.log('[WEBHOOK] ===== WEBHOOK REQUEST RECEIVED =====');
  console.log('[WEBHOOK] Method:', req.method);
  console.log('[WEBHOOK] URL:', req.url);
  console.log('[WEBHOOK] Headers:', JSON.stringify(req.headers));
  console.log('[WEBHOOK] Body type:', typeof req.body);

  let event;

  try {
    const signature = req.headers["stripe-signature"];
    console.log('[WEBHOOK] Signature:', signature);
    event = stripe.webhooks.constructEvent(
      req.body, // raw Buffer
      signature,
      WEBHOOK_SECRET
    );
    console.log('[WEBHOOK] Event constructed:', event.type);
  } catch (error) {
    // Signature verification failed -> reject.
    console.log('[WEBHOOK] Signature verification failed:', error.message);
    return res.status(400).json({ message: `Webhook Error: ${error.message}` });
  }

  try {
    switch (event.type) {
      case "payment_intent.succeeded":
        console.log('[WEBHOOK] Payment succeeded, handling...');
        await handlePaymentSucceededService(event.data.object.id);
        console.log('[WEBHOOK] Payment succeeded handled');
        break;

      case "payment_intent.payment_failed":
        console.log('[WEBHOOK] Payment failed, handling...');
        await handlePaymentFailedService(
          event.data.object.id,
          event.data.object.last_payment_error?.message
        );
        console.log('[WEBHOOK] Payment failed handled');
        break;

      default:
        console.log('[WEBHOOK] Unhandled event type:', event.type);
        // Unhandled event types are acknowledged so Stripe stops retrying.
        break;
    }

    // Always 200 once handled so Stripe doesn't keep retrying.
    console.log('[WEBHOOK] Returning 200');
    return res.status(200).json({ received: true });
  } catch (error) {
    // Returning 500 tells Stripe to retry later.
    console.log('[WEBHOOK] Error handling event:', error.message);
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
  console.log('[SIMULATE] ===== SIMULATE PAYMENT STARTED =====');
  if (!isSimulator) {
    console.log('[SIMULATE] Not in simulator mode');
    return res.status(400).json({
      message: "Simulation is only available in simulator mode"
    });
  }

  try {
    const { paymentIntentId, paymentMethod } = req.body;
    console.log('[SIMULATE] Payment intent ID:', paymentIntentId);
    console.log('[SIMULATE] Payment method:', paymentMethod);

    const intent = await stripe.paymentIntents.confirm(paymentIntentId, {
      payment_method: paymentMethod || "pm_card_visa"
    });
    console.log('[SIMULATE] Intent confirmed, status:', intent.status);

    const eventType =
      intent.status === "succeeded"
        ? "payment_intent.succeeded"
        : "payment_intent.payment_failed";
    console.log('[SIMULATE] Event type:', eventType);

    const payload = JSON.stringify({
      id: `evt_${Date.now()}`,
      type: eventType,
      data: { object: intent }
    });
    console.log('[SIMULATE] Payload created');

    const signature = stripe.webhooks.generateTestHeader(
      payload,
      WEBHOOK_SECRET
    );
    console.log('[SIMULATE] Signature generated');

    const port = process.env.PORT || 5000;
    const webhookUrl = `http://localhost:${port}/payments/webhook`;
    console.log('[SIMULATE] Sending webhook to:', webhookUrl);
    console.log('[SIMULATE] Port from env:', process.env.PORT);

    const webhookResponse = await fetch(
      webhookUrl,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "stripe-signature": signature
        },
        body: payload
      }
    );
    console.log('[SIMULATE] Webhook response status:', webhookResponse.status);
    console.log('[SIMULATE] Webhook response ok:', webhookResponse.ok);

    res.status(200).json({
      message: "Simulated payment dispatched to webhook",
      paymentIntentStatus: intent.status,
      webhookStatus: webhookResponse.status
    });
  } catch (error) {
    console.log('[SIMULATE] Error:', error.message);
    res.status(400).json({ message: error.message });
  }
};

module.exports = {
  createPayment,
  stripeWebhook,
  confirmPayment,
  simulatePayment
};
