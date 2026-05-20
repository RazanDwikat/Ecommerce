const mongoose = require("mongoose");

const addressSchema = new mongoose.Schema(
  {
    country: String,
    city: String,
    street: String,
    postalCode: String
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 3
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },

    password: {
      type: String,
      required: true,
      minlength: 6,
      select: false
    },

    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user"
    },

    phone: {
      type: String
    },

    addresses: [addressSchema]
  },
  { timestamps: true }
);

module.exports = mongoose.model("User", userSchema);