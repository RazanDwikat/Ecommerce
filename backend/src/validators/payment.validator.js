const Joi = require("joi");

// ========================
// CREATE PAYMENT
// ========================
const createPaymentSchema = Joi.object({
  orderId: Joi.string().required(),
  method: Joi.string().valid("cash", "stripe").required()
});

// ========================
// SIMULATE PAYMENT (simulator mode only)
// Mimics the customer entering a card on the frontend.
// ========================
const simulatePaymentSchema = Joi.object({
  paymentIntentId: Joi.string().required(),
  // pm_card_visa => success, anything containing "decline"/"fail" => failure
  paymentMethod: Joi.string().default("pm_card_visa")
});

module.exports = {
  createPaymentSchema,
  simulatePaymentSchema
};
