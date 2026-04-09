const mongoose = require('mongoose');

const billSchema = new mongoose.Schema({
  vehicle: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle',
    required: true
  },
  visit: {
    type: mongoose.Schema.Types.ObjectId,
  },
  worker: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  items: [
    {
      name: { type: String, required: true },
      quantity: { type: Number, required: true },
      unitPrice: { type: Number, required: true },
      totalPrice: { type: Number, required: true }
    }
  ],
  labourCharge: { type: Number, default: 0 },
  subTotal: { type: Number, required: true },
  isGstEnabled: { type: Boolean, default: false },
  gstAmount: { type: Number, default: 0 },
  total: { type: Number, required: true },
  status: { 
    type: String, 
    enum: ['Pending', 'Completed'], 
    default: 'Pending' 
  },
  billNumber: { type: String, unique: true },
  completedAt: { type: Date },
  pdfBase64: { type: String }
}, { timestamps: true });

module.exports = mongoose.model('Bill', billSchema);
