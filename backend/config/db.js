const mongoose = require('mongoose');

// Vercel Serverless optimizations: cache the database connection
let isConnected = false; 

const connectDB = async (req, res, next) => {
  if (isConnected) {
    if (next) return next();
    return;
  }

  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
    });
    
    isConnected = conn.connections[0].readyState === 1;
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    if (next) return next();
  } catch (error) {
    console.error(`MongoDB Connection Error: ${error.message}`);
    // If it fails during a request, send a 500 immediately instead of hanging
    if (res) return res.status(500).json({ message: 'Database connection failed' });
  }
};

module.exports = connectDB;
