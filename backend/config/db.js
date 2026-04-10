const mongoose = require('mongoose');

// Vercel Serverless optimizations: cache the database connection
let isConnected = false; 

const connectDB = async () => {
  if (isConnected) {
    console.log('Using existing database connection');
    return;
  }

  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
    });
    
    isConnected = conn.connections[0].readyState === 1;
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`MongoDB Connection Error: ${error.message}`);
    // In serverless environments (like Vercel), we should not call process.exit(1)
    // as it hard-crashes the entire function instance.
  }
};

module.exports = connectDB;
