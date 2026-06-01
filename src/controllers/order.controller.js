const {
  createOrderService,
  getMyOrdersService,
  getOrderByIdService,
  getAllOrdersService,
  updateOrderStatusService
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

const getOrderById = async (req, res) => {
  try {

    const order = await getOrderByIdService(
      req.user._id,
      req.params.id
    );

    res.status(200).json({
      message: "Order fetched successfully",
      order
    });

  } catch (error) {

    res.status(400).json({
      message: error.message
    });

  }
};


// ========================
// ADMIN - GET ALL ORDERS
// ========================
const getAllOrders = async (req, res) => {
  try {

    const orders = await getAllOrdersService();

    res.status(200).json({
      message: "All orders fetched successfully",
      orders
    });

  } catch (error) {

    res.status(500).json({
      message: error.message
    });

  }
};

const updateOrderStatus = async (req, res) => {
  try {

    const { id } = req.params;

    const { status } = req.body;

    const order = await updateOrderStatusService(id, status);

    res.status(200).json({
      message: "Order status updated",
      order
    });

  } catch (error) {

    res.status(400).json({
      message: error.message
    });

  }
};

module.exports = {
  createOrder,
  getMyOrders,
  getOrderById,
  getAllOrders,
  updateOrderStatus
};

