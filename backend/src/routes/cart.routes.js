const express = require("express");
const router = express.Router();

const {
  addToCart,
  getMyCart,
  updateQuantity,
  removeFromCart,
  clearCart
} = require("../controllers/cart.controller");

const authMiddleware = require("../middleware/auth.middleware");
const validate = require("../middleware/validate.middleware");

const {
  addToCartSchema,
  updateQuantitySchema
} = require("../validators/cart.validator");

// ADD
router.post("/", authMiddleware, validate(addToCartSchema), addToCart);

// GET
router.get("/", authMiddleware, getMyCart);

// UPDATE QUANTITY
router.patch(
  "/:productId",
  authMiddleware,
  validate(updateQuantitySchema),
  updateQuantity
);

// REMOVE ITEM
router.delete("/:productId", authMiddleware, removeFromCart);

// CLEAR CART
router.delete("/", authMiddleware, clearCart);

module.exports = router;