const Cart = require("../models/cart.model");
const Product = require("../models/product.model");

// ========================
// ADD TO CART
// ========================
const addToCartService = async (userId, data) => {
  const { productId, quantity } = data;

  const product = await Product.findById(productId);

  if (!product) {
    throw new Error("Product not found");
  }

  if (product.stock < quantity) {
    throw new Error("Not enough stock");
  }

  let cart = await Cart.findOne({ user: userId });

  if (!cart) {
    cart = await Cart.create({
      user: userId,
      items: [],
      totalPrice: 0
    });
  }

  const itemIndex = cart.items.findIndex(
    item => item.product.toString() === productId
  );

  if (itemIndex > -1) {
    cart.items[itemIndex].quantity += quantity;
  } else {
    cart.items.push({
      product: productId,
      quantity
    });
  }

  return await recalcCart(cart);
};

// ========================
// GET CART
// ========================
const getMyCartService = async (userId) => {
  const cart = await Cart.findOne({ user: userId })
    .populate({
      path: "items.product",
      select: "name price images stock"
    });

  if (!cart) {
    return { items: [], totalPrice: 0 };
  }

  return cart;
};

// ========================
// UPDATE QUANTITY
// ========================
const updateQuantityService = async (userId, productId, quantity) => {
  const cart = await Cart.findOne({ user: userId });

  if (!cart) {
    throw new Error("Cart not found");
  }

  const itemIndex = cart.items.findIndex(
    item => item.product.toString() === productId
  );

  if (itemIndex === -1) {
    throw new Error("Product not in cart");
  }

  const product = await Product.findById(productId);

  if (!product) {
    throw new Error("Product not found");
  }

  if (product.stock < quantity) {
    throw new Error("Not enough stock");
  }

  cart.items[itemIndex].quantity = quantity;

  return await recalcCart(cart);
};

// ========================
// REMOVE ITEM
// ========================
const removeFromCartService = async (userId, productId) => {
  const cart = await Cart.findOne({ user: userId });

  if (!cart) {
    throw new Error("Cart not found");
  }

  cart.items = cart.items.filter(
    item => item.product.toString() !== productId
  );

  return await recalcCart(cart);
};

// ========================
// CLEAR CART
// ========================
const clearCartService = async (userId) => {
  const cart = await Cart.findOne({ user: userId });

  if (!cart) {
    throw new Error("Cart not found");
  }

  cart.items = [];
  cart.totalPrice = 0;

  await cart.save();
  return cart;
};

// ========================
// HELPER FUNCTION (IMPORTANT 🔥)
// ========================
const recalcCart = async (cart) => {
  let total = 0;

  for (const item of cart.items) {
    const product = await Product.findById(item.product);
    total += product.price * item.quantity;
  }

  cart.totalPrice = total;

  await cart.save();

  return await cart.populate({
    path: "items.product",
    select: "name price images stock"
  });
};

module.exports = {
  addToCartService,
  getMyCartService,
  updateQuantityService,
  removeFromCartService,
  clearCartService
};