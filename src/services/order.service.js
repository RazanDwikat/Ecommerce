const Order = require("../models/order.model");
const Cart = require("../models/cart.model");
const Product = require("../models/product.model");

const createOrderService = async (userId) => {

    // 1. get cart
  const cart = await Cart.findOne({ user: userId });

  if (!cart || cart.items.length === 0) {
    throw new Error("Cart is empty");
  }

  let orderItems = [];
  let totalPrice = 0;

  // 2.cart → orderItems
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



// GET MY ORDERS
const getMyOrdersService = async (userId) => {

  const orders = await Order.find({ user: userId })
    .populate({
      path: "items.product",
      select: "name images price"
    })
    .sort({ createdAt: -1 }); 

  return orders;
};

module.exports = {
  createOrderService,
  getMyOrdersService
};
