const express = require("express");
const path = require("path");
const cors = require("cors");

const app = express();

const { stripeWebhook } = require("./controllers/payment.controller");

const corsOptions = {
  origin: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: true,
};

app.use(cors(corsOptions));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

const authRoutes = require("./routes/auth.routes");

const productRoutes = require("./routes/product.routes");

const categoryRoutes = require("./routes/category.routes");

const cartRoutes = require("./routes/cart.routes");

const orderRoutes = require("./routes/order.routes");

const paymentRoutes = require("./routes/payment.routes");

const reviewRoutes = require("./routes/review.routes");



app.use("/orders", orderRoutes);

app.use("/cart", cartRoutes);

app.use("/categories", categoryRoutes);

app.use("/auth", authRoutes);

app.use("/products", productRoutes);

app.use("/payments", paymentRoutes);

app.use("/reviews", reviewRoutes);

module.exports = app;