require("dotenv").config();

const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const connectDB = require("../config/db");
const User = require("../models/user.model");

const createAdmin = async () => {
  try {

    await connectDB();

   
    const existingAdmin = await User.findOne({
      email: "Alma@gmail.com"
    });

    if (existingAdmin) {
      console.log("Admin already exists");
      process.exit();
    }

  
    const hashedPassword = await bcrypt.hash("123456", 10);

  
    await User.create({
      name: "Admin",
      email: "Alma@gmail.com",
      password: hashedPassword,
      role: "admin"
    });

    console.log("Admin created successfully 🔥");

    process.exit();

  } catch (error) {

    console.error(error);

    process.exit(1);
  }
};

createAdmin();