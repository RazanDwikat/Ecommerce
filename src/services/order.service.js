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

    // 4. build snapshot 🔥
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
  const order = await Order.create({
    user: userId,
    items: orderItems,
    totalPrice,
    status: "pending",
    paymentStatus: "pending"
  });

  // 6. reduce stock
  for (const item of cart.items) {
    await Product.findByIdAndUpdate(item.product, {
      $inc: { stock: -item.quantity }
    });
  }

  // 7. clear cart
  cart.items = [];
  cart.totalPrice = 0;
  await cart.save();

  return order;
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
      createdAt: 1
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
  getMyOrdersService,
  getOrderByIdService,
  getAllOrdersService,
  updateOrderStatusService
};