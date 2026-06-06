const Joi = require("joi");

const createReviewSchema = Joi.object({
  rating: Joi.number()
    .min(1)
    .max(5)
    .required(),

  comment: Joi.string()
    .trim()
    .max(1000)
    .allow("")
});

const updateReviewSchema = Joi.object({
  rating: Joi.number()
    .min(1)
    .max(5),

  comment: Joi.string()
    .trim()
    .max(1000)
    .allow("")
}).min(1);

module.exports = {
  createReviewSchema,
  updateReviewSchema
};