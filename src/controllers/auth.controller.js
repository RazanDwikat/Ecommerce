const {
  registerService,
  loginService
} = require("../services/auth.service");

// REGISTER
const register = async (req, res) => {
  try {
    const user = await registerService(req.body);

    res.status(201).json({
      message: "User created successfully",
      user
    });
  } catch (error) {
    res.status(400).json({
      message: error.message
    });
  }
};

// LOGIN
const login = async (req, res) => {
  try {
    const result = await loginService(req.body);

    res.status(200).json({
      message: "Login successful",
      user: result.user,
      token: result.token
    });
  } catch (error) {
    res.status(400).json({
      message: error.message
    });
  }
};

module.exports = {
  register,
  login
};