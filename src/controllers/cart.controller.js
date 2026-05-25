const {
  addToCartService
} = require("../services/cart.service");

const addToCart = async (req, res) => {
  try {

    const cart = await addToCartService(
      req.user._id,
      req.body
    );

    res.status(200).json({
      message: "Product added to cart",
      cart
    });

  } catch (error) {

    res.status(400).json({
      message: error.message
    });

  }
};

module.exports = {
  addToCart
};