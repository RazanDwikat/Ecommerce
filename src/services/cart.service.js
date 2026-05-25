const Cart = require("../models/cart.model");
const Product = require("../models/product.model");

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

 
  let total = 0;

  for (const item of cart.items) {

    const itemProduct = await Product.findById(item.product);

    total += itemProduct.price * item.quantity;
  }

  cart.totalPrice = total;

  await cart.save();

  return cart;
};

const getMyCartService = async (userId) => {

  const cart = await Cart.findOne({
    user: userId
  }).populate({
    path: "items.product",
    select: "name price images stock"
  });

  if (!cart) {
    return {
      items: [],
      totalPrice: 0
    };
  }

  return cart;
};

module.exports = {
  addToCartService,
    getMyCartService
};