const {
  createOrderService
} = require("../services/order.service");

const createOrder = async (req, res) => {
  try {

    const order = await createOrderService(req.user._id);

    res.status(201).json({
      message: "Order created successfully",
      order
    });

  } catch (error) {

    res.status(400).json({
      message: error.message
    });

  }
};

module.exports = {
  createOrder
};