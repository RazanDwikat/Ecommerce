const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema(
  {
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
      required: true
    },

    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    amount: {
      type: Number,
      required: true
    },

    method: {
      type: String,
      enum: ["card", "cash"],
      required: true
    },

    status: {
      type: String,
      enum: ["pending", "completed", "failed"],
      default: "pending"
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model("Payment", paymentSchema);