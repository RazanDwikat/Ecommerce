const Review = require("../models/review.model");
const Product = require("../models/product.model");
const Order = require("../models/order.model");


const recalculateProductRating = async (productId) => {

  const reviews = await Review.find({
    product: productId
  });

  const reviewsCount = reviews.length;

  let averageRating = 0;

  if (reviewsCount > 0) {

    const totalRating = reviews.reduce(
      (sum, review) => sum + review.rating,
      0
    );

    averageRating = totalRating / reviewsCount;
  }

  await Product.findByIdAndUpdate(
    productId,
    {
      averageRating,
      reviewsCount
    }
  );
};


const createReviewService = async (
  userId,
  productId,
  data
) => {

  const { rating, comment } = data;

  const product = await Product.findById(productId);

  if (!product) {
    throw new Error("Product not found");
  }

  const purchasedProduct = await Order.findOne({
    user: userId,
    paymentStatus: "paid",
    "items.product": productId
  });

  if (!purchasedProduct) {
    throw new Error(
      "You can only review products you purchased"
    );
  }

  const existingReview = await Review.findOne({
    user: userId,
    product: productId
  });

  if (existingReview) {
    throw new Error(
      "You already reviewed this product"
    );
  }

  const review = await Review.create({
    user: userId,
    product: productId,
    rating,
    comment
  });

  await recalculateProductRating(productId);

  return review;
};


const getProductReviewsService = async (
  productId
) => {

  const product = await Product.findById(productId);

  if (!product) {
    throw new Error("Product not found");
  }

  const reviews = await Review.find({
    product: productId
  })
    .populate({
      path: "user",
      select: "name"
    })
    .sort({ createdAt: -1 });

  return reviews;
};


const updateReviewService = async (
  userId,
  reviewId,
  data
) => {

  const review = await Review.findById(reviewId);

  if (!review) {
    throw new Error("Review not found");
  }

  if (
    review.user.toString() !== userId.toString()
  ) {
    throw new Error("Unauthorized access");
  }

  if (data.rating !== undefined) {
    review.rating = data.rating;
  }

  if (data.comment !== undefined) {
    review.comment = data.comment;
  }

  await review.save();

  await recalculateProductRating(
    review.product
  );

  return review;
};




const deleteReviewService = async (
  userId,
  reviewId
) => {

  const review = await Review.findById(reviewId);

  if (!review) {
    throw new Error("Review not found");
  }

  if (
    review.user.toString() !== userId.toString()
  ) {
    throw new Error("Unauthorized access");
  }

  const productId = review.product;

  await review.deleteOne();

  await recalculateProductRating(productId);

  return;
};


module.exports = {
  createReviewService,
  getProductReviewsService,
  updateReviewService,
  deleteReviewService,
  recalculateProductRating
};