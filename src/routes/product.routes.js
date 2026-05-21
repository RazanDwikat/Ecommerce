const express = require("express");
const router = express.Router();

const {
  createProduct,
  getAllProducts,
  getProductById,
  updateProduct,
  deleteProduct
} = require("../controllers/product.controller");

const authMiddleware = require("../middleware/auth.middleware");
const adminMiddleware = require("../middleware/admin.middleware");
const validate = require("../middleware/validate.middleware");

const {
  createProductSchema,
  updateProductSchema
} = require("../validators/product.validator");


router.get("/", getAllProducts);
router.get("/:id", getProductById);

// ADMIN ONLY
router.post(
  "/",
  authMiddleware,
  adminMiddleware,
  validate(createProductSchema),
  createProduct
);

router.patch(
  "/:id",
  authMiddleware,
  adminMiddleware,
  validate(updateProductSchema),
  updateProduct
);

router.delete(
  "/:id",
  authMiddleware,
  adminMiddleware,
  deleteProduct
);

module.exports = router;