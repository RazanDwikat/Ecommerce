const Joi = require("joi");

const addToCartSchema = Joi.object({
  productId: Joi.string().required(),

  quantity: Joi.number().min(1).required()
});

const updateQuantitySchema = Joi.object({
  quantity: Joi.number().min(1).required()
});

module.exports = {
  addToCartSchema,
  updateQuantitySchema
};