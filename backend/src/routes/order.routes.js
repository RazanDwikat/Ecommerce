const express = require("express");
const router = express.Router();

const {
  createOrder,
  getMyOrders,
  getOrderById,
  getAllOrders,
  updateOrderStatus
} = require("../controllers/order.controller");
const validate = require("../middleware/validate.middleware");

const {
  updateOrderStatusSchema
} = require("../validators/order.validator");

const authMiddleware = require("../middleware/auth.middleware");
const adminMiddleware = require("../middleware/admin.middleware");
router.post(
  "/",
  authMiddleware,
  createOrder
);

router.get("/my-orders", authMiddleware, getMyOrders);

router.get("/:id", authMiddleware, getOrderById);

router.get( "/admin/orders", authMiddleware, adminMiddleware, getAllOrders);

router.patch( "/admin/orders/:id/status", authMiddleware, adminMiddleware, validate(updateOrderStatusSchema), updateOrderStatus);
module.exports = router;