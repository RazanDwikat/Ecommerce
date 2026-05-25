const {
  addToCartService,
  getMyCartService
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

const getMyCart = async (req, res) => {
  try {

    const cart = await getMyCartService(req.user._id);

    res.status(200).json({
      message: "Cart fetched successfully",
      cart
    });

  } catch (error) {

    res.status(500).json({
      message: error.message
    });

  }
};

module.exports = {
  addToCart,
  getMyCart
};