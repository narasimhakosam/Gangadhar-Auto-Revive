const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('../config/db');

// Load env vars
dotenv.config();

// Remove the synchronous top-level call.
// We will use connectDB as a middleware inside the request lifecycle to ensure it's awaited.

const app = express();

// Middleware
const corsOptions = {
  origin: [
    'https://gangadhar-auto-revive.vercel.app',
    'http://localhost:5000',
    'http://localhost:5001' // Add any common local frontend ports
  ],
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));
// Increase limit for Base64 images
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Ensure database connection is established BEFORE executing routes
app.use(connectDB);

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
