const Joi = require("joi");

const createCategorySchema = Joi.object({
  name: Joi.string().trim().required(),
  description: Joi.string().allow("").optional()
});

const updateCategorySchema = Joi.object({
  name: Joi.string().trim().optional(),
  description: Joi.string().allow("").optional()
});

module.exports = {
  createCategorySchema,
  updateCategorySchema
};