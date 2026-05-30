const {
  addToCartService,
  getMyCartService,
  updateQuantityService,
  removeFromCartService,
  clearCartService
} = require("../services/cart.service");

// ADD
const addToCart = async (req, res) => {
  try {
    const cart = await addToCartService(req.user._id, req.body);

    res.status(200).json({
      message: "Product added to cart",
      cart
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// GET
const getMyCart = async (req, res) => {
  try {
    const cart = await getMyCartService(req.user._id);

    res.status(200).json({
      message: "Cart fetched successfully",
      cart
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// UPDATE QUANTITY
const updateQuantity = async (req, res) => {
  try {
    const { productId } = req.params;

    const cart = await updateQuantityService(
      req.user._id,
      productId,
      req.body.quantity
    );

    res.status(200).json({
      message: "Quantity updated successfully",
      cart
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// REMOVE ITEM
const removeFromCart = async (req, res) => {
  try {
    const { productId } = req.params;

    const cart = await removeFromCartService(
      req.user._id,
      productId
    );

    res.status(200).json({
      message: "Product removed from cart",
      cart
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// CLEAR CART
const clearCart = async (req, res) => {
  try {
    const cart = await clearCartService(req.user._id);

    res.status(200).json({
      message: "Cart cleared successfully",
      cart
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = {
  addToCart,
  getMyCart,
  updateQuantity,
  removeFromCart,
  clearCart
};