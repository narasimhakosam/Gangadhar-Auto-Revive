const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`MongoDB Connection Error: ${error.message}`);
    // In serverless environments (like Vercel), we should not call process.exit(1)
    // as it hard-crashes the entire function instance.
  }
};

module.exports = connectDB;
