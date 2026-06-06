const Joi = require("joi");


const createProductSchema = Joi.object({
  name: Joi.string().trim().required(),

  description: Joi.string().trim().required(),

  price: Joi.number().min(0).required(),

  stock: Joi.number().min(0).required(),

  category: Joi.string().required(),

  images: Joi.array().items(Joi.string()).optional()
});


const updateProductSchema = Joi.object({
  name: Joi.string().trim().optional(),

  description: Joi.string().trim().optional(),

  price: Joi.number().min(0).optional(),

  stock: Joi.number().min(0).optional(),

  category: Joi.string().optional(),

  images: Joi.array().items(Joi.string()).optional()
});

module.exports = {
  createProductSchema,
  updateProductSchema
};