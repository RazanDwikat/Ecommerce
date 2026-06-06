const Joi = require("joi");

// ========================
// UPDATE ORDER STATUS
// ========================
const updateOrderStatusSchema = Joi.object({
  status: Joi.string()
    .valid("pending", "processing", "shipped", "delivered", "cancelled")
    .required()
});

module.exports = {
  updateOrderStatusSchema
};