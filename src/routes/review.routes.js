const express = require("express");

const router = express.Router();

const {
  createReview,
  getProductReviews,
  updateReview,
  deleteReview
} = require("../controllers/review.controller");

const authMiddleware = require("../middleware/auth.middleware");

const validate = require("../middleware/validate.middleware");

const {
  createReviewSchema,
  updateReviewSchema
} = require("../validators/review.validator");


router.post(
  "/products/:productId",
  authMiddleware,
  validate(createReviewSchema),
  createReview
);


router.get(
  "/products/:productId",
  getProductReviews
);


router.patch(
  "/:reviewId",
  authMiddleware,
  validate(updateReviewSchema),
  updateReview
);


router.delete(
  "/:reviewId",
  authMiddleware,
  deleteReview
);

module.exports = router;