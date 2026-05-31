const express = require("express");
const app = express();

app.use(express.json());

const authRoutes = require("./routes/auth.routes");
const productRoutes = require("./routes/product.routes");
const categoryRoutes = require("./routes/category.routes");
const cartRoutes = require("./routes/cart.routes");
const orderRoutes = require("./routes/order.routes");

app.use("/orders", orderRoutes);
app.use("/cart", cartRoutes);
app.use("/categories", categoryRoutes);
app.use("/auth", authRoutes);
app.use("/products", productRoutes);
module.exports = app;