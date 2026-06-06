const {
  createReviewService,
  getProductReviewsService,
  updateReviewService,
  deleteReviewService
} = require("../services/review.service");


const createReview = async (req, res) => {
  try {

    const review = await createReviewService(
      req.user._id,
      req.params.productId,
      req.body
    );

    res.status(201).json({
      message: "Review created successfully",
      review
    });

  } catch (error) {

    res.status(400).json({
      message: error.message
    });

  }
};


const getProductReviews = async (req, res) => {
  try {

    const reviews = await getProductReviewsService(
      req.params.productId
    );

    res.status(200).json({
      message: "Reviews fetched successfully",
      reviews
    });

  } catch (error) {

    res.status(400).json({
      message: error.message
    });

  }
};


const updateReview = async (req, res) => {
  try {

    const review = await updateReviewService(
      req.user._id,
      req.params.reviewId,
      req.body
    );

    res.status(200).json({
      message: "Review updated successfully",
      review
    });

  } catch (error) {

    res.status(400).json({
      message: error.message
    });

  }
};

const deleteReview = async (req, res) => {
  try {

    await deleteReviewService(
      req.user._id,
      req.params.reviewId
    );

    res.status(200).json({
      message: "Review deleted successfully"
    });

  } catch (error) {

    res.status(400).json({
      message: error.message
    });

  }
};

module.exports = {
  createReview,
  getProductReviews,
  updateReview,
  deleteReview
};