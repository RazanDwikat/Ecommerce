const mongoose = require("mongoose");

const orderItemSchema = new mongoose.Schema(
  {
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      required: true
    },

    quantity: {
      type: Number,
      required: true,
      min: 1
    },

    price: {
      type: Number,
      required: true
    }
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    items: [orderItemSchema],

    totalPrice: {
      type: Number,
      required: true
    },

    status: {
      type: String,
      enum: ["pending", "shipped", "delivered", "cancelled"],
      default: "pending"
    },

    paymentStatus: {
      type: String,
      enum: ["pending", "paid"],
      default: "pending"
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model("Order", orderSchema);