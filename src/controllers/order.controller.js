const {
  createOrderService,
  getMyOrdersService
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



// MY ORDERS
const getMyOrders = async (req, res) => {
  try {
    const orders = await getMyOrdersService(req.user._id);

    res.status(200).json({
      message: "My orders fetched successfully",
      orders
    });
  } catch (error) {
    res.status(500).json({
      message: error.message
    });
  }
};

module.exports = {
  createOrder,
  getMyOrders
};

