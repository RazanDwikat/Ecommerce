const {
  createCategoryService,
  getAllCategoriesService,
  getCategoryByIdService,
  updateCategoryService,
  deleteCategoryService,
  restoreCategoryService
} = require("../services/category.service");

// CREATE
const createCategory = async (req, res) => {
  try {
    const category = await createCategoryService(req.body);

    res.status(201).json({
      message: "Category created successfully",
      category
    });

  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// GET ALL
const getAllCategories = async (req, res) => {
  const categories = await getAllCategoriesService();

  res.json({
    categories
  });
};

// GET ONE
const getCategoryById = async (req, res) => {
  try {
    const category = await getCategoryByIdService(req.params.id);

    res.json({ category });

  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

// UPDATE
const updateCategory = async (req, res) => {
  try {
    const category = await updateCategoryService(req.params.id, req.body);

    res.json({
      message: "Category updated successfully",
      category
    });

  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

// DELETE
const deleteCategory = async (req, res) => {
  try {
    await deleteCategoryService(req.params.id);

    res.json({
      message: "Category deleted successfully"
    });

  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

const restoreCategory = async (req, res) => {
  try {
    const category = await restoreCategoryService(req.params.id);

    res.json({
      message: "Category restored successfully",
      category
    });

  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

module.exports = {
  createCategory,
  getAllCategories,
  getCategoryById,
  updateCategory,
  deleteCategory,
  restoreCategory
};