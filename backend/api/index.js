const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('../config/db');

// Load env vars
dotenv.config();

// Connect to database
connectDB();

const app = express();

// Middleware
app.use(cors());
// Increase limit for Base64 images
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Routes
app.use('/api/auth', require('../routes/authRoutes'));
app.use('/api/vehicles', require('../routes/vehicleRoutes'));
app.use('/api/billing', require('../routes/billingRoutes'));
app.use('/api/images', require('../routes/imageRoutes'));

app.get('/', (req, res) => {
  res.send('API is running (Vercel API Mode)...');
});

// Export the app for Vercel
module.exports = app;
