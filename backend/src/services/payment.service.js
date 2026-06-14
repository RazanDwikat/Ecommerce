const Order = require("../models/order.model");
const Payment = require("../models/payment.model");
const { fulfillOrderService } = require("./order.service");
const { stripe } = require("../config/stripe");

const CURRENCY = process.env.PAYMENT_CURRENCY || "usd";

// =====================================================
// CREATE PAYMENT (entry point for both cash and stripe)
// =====================================================
const createPaymentService = async (userId, orderId, method) => {

  const order = await Order.findById(orderId);

  if (!order) {
    throw new Error("Order not found");
  }

  if (order.user.toString() !== userId.toString()) {
    throw new Error("Unauthorized access");
  }

  if (order.paymentStatus === "paid") {
    throw new Error("Order is already paid");
  }

  if (method === "cash") {
    return payWithCash(userId, order);
  }

  if (method === "stripe") {
    return payWithStripe(userId, order);
  }

  throw new Error("Invalid payment method");
};

// ---------- CASH (cash on delivery) ----------
// Cash has no online charge: we reserve the stock immediately (clear cart +
// decrement stock) and move the order to "processing". paymentStatus stays
// "pending" because the money is collected on delivery.
const payWithCash = async (userId, order) => {

  await fulfillOrderService(order);

  const payment = await Payment.create({
    order: order._id,
    user: userId,
    amount: order.totalPrice,
    currency: CURRENCY,
    method: "cash",
    status: "pending"
  });

  order.paymentMethod = "cash";
  order.payment = payment._id;
  order.status = "processing";
  await order.save();

  return { order, payment };
};

// ---------- STRIPE ----------
// Create a PaymentIntent and return its clientSecret. Stock is NOT touched yet;
// it is only reserved once the payment succeeds (handled via webhook).
const payWithStripe = async (userId, order) => {

  const intent = await stripe.paymentIntents.create({
    amount: Math.round(order.totalPrice * 100), // smallest currency unit (cents)
    currency: CURRENCY,
    metadata: {
      orderId: order._id.toString(),
      userId: userId.toString()
    }
  });

  const payment = await Payment.create({
    order: order._id,
    user: userId,
    amount: order.totalPrice,
    currency: CURRENCY,
    method: "stripe",
    status: "pending",
    paymentIntentId: intent.id,
    clientSecret: intent.client_secret
  });

  order.paymentMethod = "stripe";
  order.payment = payment._id;
  await order.save();

  return {
    order,
    paymentId: payment._id,
    paymentIntentId: intent.id,
    clientSecret: intent.client_secret
  };
};

// =====================================================
// PAYMENT SUCCEEDED (called by webhook / confirm)
// Idempotent: safe to call multiple times for the same intent.
// =====================================================
const handlePaymentSucceededService = async (paymentIntentId) => {
  console.log('[PAYMENT SERVICE] Handling payment succeeded for intent:', paymentIntentId);

  const payment = await Payment.findOne({ paymentIntentId });

  if (!payment) {
    console.log('[PAYMENT SERVICE] Payment not found for intent:', paymentIntentId);
    throw new Error("Payment not found for intent");
  }

  console.log('[PAYMENT SERVICE] Payment found, status:', payment.status);

  if (payment.status === "completed") {
    console.log('[PAYMENT SERVICE] Payment already completed, skipping');
    return payment; // already processed -> do not reduce stock twice
  }

  const order = await Order.findById(payment.order);

  if (!order) {
    console.log('[PAYMENT SERVICE] Order not found for payment');
    throw new Error("Order not found for payment");
  }

  console.log('[PAYMENT SERVICE] Order found, calling fulfillOrderService');
  await fulfillOrderService(order);
  console.log('[PAYMENT SERVICE] fulfillOrderService completed');

  payment.status = "completed";
  payment.failureReason = undefined;
  await payment.save();

  order.paymentStatus = "paid";
  order.status = "processing";
  await order.save();

  console.log('[PAYMENT SERVICE] Payment succeeded handling completed');
  return payment;
};

// =====================================================
// PAYMENT FAILED (called by webhook / confirm)
// =====================================================
const handlePaymentFailedService = async (paymentIntentId, reason) => {

  const payment = await Payment.findOne({ paymentIntentId });

  if (!payment) {
    throw new Error("Payment not found for intent");
  }

  if (payment.status === "completed") {
    return payment; // do not override a successful payment
  }

  payment.status = "failed";
  payment.failureReason = reason || "Payment failed";
  await payment.save();

  await Order.findByIdAndUpdate(payment.order, {
    paymentStatus: "failed"
  });

  return payment;
};

// =====================================================
// CONFIRM (fallback): pull the intent status from Stripe
// and reconcile our records. Useful when not running a
// webhook listener.
// =====================================================
const confirmPaymentService = async (userId, paymentIntentId) => {

  const payment = await Payment.findOne({ paymentIntentId });

  if (!payment) {
    throw new Error("Payment not found");
  }

  if (payment.user.toString() !== userId.toString()) {
    throw new Error("Unauthorized access");
  }

  const intent = await stripe.paymentIntents.retrieve(paymentIntentId);

  if (intent.status === "succeeded") {
    return handlePaymentSucceededService(paymentIntentId);
  }

  return handlePaymentFailedService(
    paymentIntentId,
    intent.last_payment_error?.message
  );
};

module.exports = {
  createPaymentService,
  handlePaymentSucceededService,
  handlePaymentFailedService,
  confirmPaymentService
};
