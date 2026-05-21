const Category = require("../models/category.model");

// CREATE
const createCategoryService = async (data) => {
  const existing = await Category.findOne({ name: data.name });

  if (existing) {
    throw new Error("Category already exists");
  }

  const category = await Category.create(data);
  return category;
};

// GET ALL
const getAllCategoriesService = async () => {
  return await Category.find({ isDeleted: false });;
};

// GET ONE
const getCategoryByIdService = async (id) => {
  const category = await Category.findOne({ _id: id, isDeleted: false });

  if (!category) {
    throw new Error("Category not found");
  }

  return category;
};

// UPDATE
const updateCategoryService = async (id, data) => {
  const category = await Category.findOneAndUpdate(
    { _id: id, isDeleted: false },
    data,
    { new: true }
  );

  if (!category) {
    throw new Error("Category not found");
  }

  return category;
};

// DELETE
const deleteCategoryService = async (id) => {
  const category = await Category.findById(id);

  if (!category) {
    throw new Error("Category not found");
  }

  category.isDeleted = true;
  await category.save();

  return category;
};

const restoreCategoryService = async (id) => {
  const category = await Category.findById(id);

  if (!category) {
    throw new Error("Category not found");
  }

  category.isDeleted = false;
  await category.save();

  return category;
};

module.exports = {
  createCategoryService,
  getAllCategoriesService,
  getCategoryByIdService,
  updateCategoryService,
  deleteCategoryService,
  restoreCategoryService
};