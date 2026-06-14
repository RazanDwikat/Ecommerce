const Order = require("../models/order.model");
const Cart = require("../models/cart.model");
const Product = require("../models/product.model");

// ========================
// CREATE ORDER (CHECKOUT)
// ========================
const createOrderService = async (userId) => {

  // 1. get cart
  const cart = await Cart.findOne({ user: userId });

  if (!cart || cart.items.length === 0) {
    throw new Error("Cart is empty");
  }

  let orderItems = [];
  let totalPrice = 0;

  // 2. cart → orderItems (snapshot)
  for (const item of cart.items) {

    const product = await Product.findById(item.product);

    if (!product) {
      throw new Error("Product not found");
    }

    // 3. check stock
    if (product.stock < item.quantity) {
      throw new Error(`Not enough stock for ${product.name}`);
    }

    // 4. build snapshot 
    orderItems.push({
      product: product._id,
      name: product.name,
      image: product.images?.[0] || null,
      quantity: item.quantity,
      price: product.price
    });

    totalPrice += product.price * item.quantity;
  }

  // 5. create order
  // NOTE: stock is NOT reduced and the cart is NOT cleared here. Both happen
  // only after a successful payment (see fulfillOrderService), so a failed
  // payment never consumes inventory or empties the customer's cart.
  const order = await Order.create({
    user: userId,
    items: orderItems,
    totalPrice,
    status: "pending",
    paymentStatus: "pending"
  });

  return order;
};

// =========================================
// FULFILL ORDER (reduce stock + clear cart)
// =========================================
// Called once a payment is confirmed (cash on checkout, or Stripe on success).
// Stock is decremented atomically with a stock-availability guard so we never
// oversell between order creation and payment confirmation.
const fulfillOrderService = async (order) => {
  console.log('[ORDER SERVICE] Fulfilling order:', order._id);
  console.log('[ORDER SERVICE] Order items:', order.items.length);

  for (const item of order.items) {
    console.log('[ORDER SERVICE] Processing item:', item.name, 'quantity:', item.quantity);
    const updated = await Product.findOneAndUpdate(
      { _id: item.product, stock: { $gte: item.quantity } },
      { $inc: { stock: -item.quantity } },
      { new: true }
    );

    if (!updated) {
      console.log('[ORDER SERVICE] Not enough stock for:', item.name);
      throw new Error(`Not enough stock for ${item.name}`);
    }
    console.log('[ORDER SERVICE] Stock reduced for:', item.name);
  }

  console.log('[ORDER SERVICE] Clearing cart for user:', order.user);
  await Cart.findOneAndUpdate(
    { user: order.user },
    { $set: { items: [], totalPrice: 0 } }
  );
  console.log('[ORDER SERVICE] Cart cleared');
};

// ========================
// GET MY ORDERS (LIST)
// ========================
const getMyOrdersService = async (userId) => {

  const orders = await Order.find(
    { user: userId },
    {
      totalPrice: 1,
      status: 1,
      paymentStatus: 1,
      createdAt: 1,
      items: 1
    }
  )
  .sort({ createdAt: -1 });

  return orders;
};


const getOrderByIdService = async (userId, orderId) => {

  const order = await Order.findById(orderId);

  if (!order) {
    throw new Error("Order not found");
  }

  if (order.user.toString() !== userId.toString()) {
    throw new Error("Unauthorized access");
  }

  return order;
};

const getAllOrdersService = async () => {

  const orders = await Order.find()
    .sort({ createdAt: -1 });

  return orders;
};

const updateOrderStatusService = async (orderId, status) => {

  const order = await Order.findById(orderId);

  if (!order) {
    throw new Error("Order not found");
  }

  order.status = status;

  await order.save();

  return order;
};

module.exports = {
  createOrderService,
  fulfillOrderService,
  getMyOrdersService,
  getOrderByIdService,
  getAllOrdersService,
  updateOrderStatusService
};