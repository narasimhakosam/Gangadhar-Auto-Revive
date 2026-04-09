const mongoose = require('mongoose');

const sparePartSchema = new mongoose.Schema({
  name: { type: String, required: true },
  quantity: { type: Number, required: true },
  unitPrice: { type: Number, required: true },
});

const visitSchema = new mongoose.Schema({
  date: { type: Date, default: Date.now },
  description: { type: String, required: true },
  worker: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  parts: [sparePartSchema],
  labourCharge: { type: Number, default: 0 },
  images: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Image'
  }],
  bill: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Bill'
  }
});

const vehicleSchema = new mongoose.Schema({
  registrationNumber: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true,
  },
  model: { type: String },
  ownerName: { type: String },
  ownerPhone: { type: String },
  user: {
     type: mongoose.Schema.Types.ObjectId,
     ref: 'User', // Reference to customer if assigned
  },
  visits: [visitSchema]
}, { timestamps: true });

module.exports = mongoose.model('Vehicle', vehicleSchema);
