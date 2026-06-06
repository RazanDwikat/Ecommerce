const express = require("express");
const router = express.Router();

const {
  createCategory,
  getAllCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
  restoreCategory
} = require("../controllers/category.controller");

const authMiddleware = require("../middleware/auth.middleware");
const adminMiddleware = require("../middleware/admin.middleware");
const validate = require("../middleware/validate.middleware");

const {
  createCategorySchema,
  updateCategorySchema
} = require("../validators/category.validator");

// PUBLIC
router.get("/", getAllCategories);
router.get("/:id", getCategoryById);

// ADMIN ONLY
router.post(
  "/",
  authMiddleware,
  adminMiddleware,
  validate(createCategorySchema),
  createCategory
);

router.patch(
  "/:id",
  authMiddleware,
  adminMiddleware,
  validate(updateCategorySchema),
  updateCategory
);

router.delete(
  "/:id",
  authMiddleware,
  adminMiddleware,
  deleteCategory
);

router.patch(
  "/restore/:id",
  authMiddleware,
  adminMiddleware,
  restoreCategory
);

module.exports = router;