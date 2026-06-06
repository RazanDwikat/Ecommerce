const express = require("express");
const router = express.Router();

const {
  createPayment,
  confirmPayment,
  simulatePayment
} = require("../controllers/payment.controller");

const authMiddleware = require("../middleware/auth.middleware");
const validate = require("../middleware/validate.middleware");

const {
  createPaymentSchema,
  simulatePaymentSchema
} = require("../validators/payment.validator");

// NOTE: POST /payments/webhook is registered directly in app.js (before the
// JSON body parser) because Stripe signature verification needs the raw body.

// Start a payment (cash or stripe)
router.post(
  "/",
  authMiddleware,
  validate(createPaymentSchema),
  createPayment
);

// Simulator-only: pretend the customer confirmed a card on the frontend
router.post(
  "/simulate",
  authMiddleware,
  validate(simulatePaymentSchema),
  simulatePayment
);

// Fallback reconciliation if not relying on the webhook
router.post(
  "/:paymentIntentId/confirm",
  authMiddleware,
  confirmPayment
);

module.exports = router;
