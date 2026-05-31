const express = require("express");
const router = express.Router();

const {
  createOrder,
  getMyOrders
} = require("../controllers/order.controller");

const authMiddleware = require("../middleware/auth.middleware");

router.post(
  "/",
  authMiddleware,
  createOrder
);

router.get("/my-orders", authMiddleware, getMyOrders);

module.exports = router;