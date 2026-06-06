const Product = require("../models/product.model");
const Category = require("../models/category.model");

// CREATE PRODUCT
const createProductService = async (data) => {
  const categoryExists = await Category.findById(data.category);

  if (!categoryExists) {
    throw new Error("Category not found");
  }

  const product = await Product.create(data);
  return product;
};

// GET ALL PRODUCTS (advanced)
const getAllProductsService = async (query) => {
  const {
    search,
    category,
    minPrice,
    maxPrice,
    sort,
    page = 1,
    limit = 10
  } = query;

  let filter = {};

  if (search) {
    filter.name = { $regex: search, $options: "i" };
  }

  if (category) {
    filter.category = category;
  }

  if (minPrice || maxPrice) {
    filter.price = {};
    if (minPrice) filter.price.$gte = Number(minPrice);
    if (maxPrice) filter.price.$lte = Number(maxPrice);
  }

  const skip = (page - 1) * limit;

  let sortOption = {};
  if (sort) {
    const order = sort.startsWith("-") ? -1 : 1;
    const field = sort.replace("-", "");
    sortOption[field] = order;
  }

  const products = await Product.find(filter)
    .populate("category")
    .sort(sortOption)
    .skip(skip)
    .limit(Number(limit));

  const total = await Product.countDocuments(filter);

  return {
    products,
    total,
    page: Number(page),
    totalPages: Math.ceil(total / limit)
  };
};

// GET ONE
const getProductByIdService = async (id) => {
  const product = await Product.findById(id).populate("category");

  if (!product) {
    throw new Error("Product not found");
  }

  return product;
};

// UPDATE
const updateProductService = async (id, data) => {
  const product = await Product.findByIdAndUpdate(id, data, {
    new: true
  });

  if (!product) {
    throw new Error("Product not found");
  }

  return product;
};

// DELETE
const deleteProductService = async (id) => {
  const product = await Product.findByIdAndDelete(id);

  if (!product) {
    throw new Error("Product not found");
  }

  return product;
};

module.exports = {
  createProductService,
  getAllProductsService,
  getProductByIdService,
  updateProductService,
  deleteProductService
};