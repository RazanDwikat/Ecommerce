const express = require("express");

const router = express.Router();

const {
  addToCart
} = require("../controllers/cart.controller");

const authMiddleware = require("../middleware/auth.middleware");

const validate = require("../middleware/validate.middleware");

const {
  addToCartSchema
} = require("../validators/cart.validator");

router.post(
  "/",
  authMiddleware,
  validate(addToCartSchema),
  addToCart
);

module.exports = router;