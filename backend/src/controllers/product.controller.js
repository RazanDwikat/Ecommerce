const {
  createProductService,
  getAllProductsService,
  getProductByIdService,
  updateProductService,
  deleteProductService
} = require("../services/product.service");

// CREATE
const createProduct = async (req, res) => {
  try {
    const product = await createProductService(req.body);

    res.status(201).json({
      message: "Product created successfully",
      product
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// GET ALL
const getAllProducts = async (req, res) => {
  try {
    const result = await getAllProductsService(req.query);

    res.status(200).json({
      message: "Products fetched successfully",
      ...result
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// GET ONE
const getProductById = async (req, res) => {
  try {
    const product = await getProductByIdService(req.params.id);

    res.status(200).json({ product });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

// UPDATE
const updateProduct = async (req, res) => {
  try {
    const product = await updateProductService(req.params.id, req.body);

    res.status(200).json({
      message: "Product updated successfully",
      product
    });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

// DELETE
const deleteProduct = async (req, res) => {
  try {
    await deleteProductService(req.params.id);

    res.status(200).json({
      message: "Product deleted successfully"
    });
  } catch (error) {
    res.status(404).json({ message: error.message });
  }
};

module.exports = {
  createProduct,
  getAllProducts,
  getProductById,
  updateProduct,
  deleteProduct
};