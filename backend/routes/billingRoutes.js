const express = require('express');
const router = express.Router();
const { 
  createBill, 
  getBillById, 
  getBills, 
  getBillingStats, 
  updateBill,
  updateBillStatus 
} = require('../controllers/billingController');
const { protect, workerOrAdmin, adminOnly } = require('../middleware/authMiddleware');

router.route('/')
  .post(protect, workerOrAdmin, createBill)
  .get(protect, getBills);

router.get('/stats', protect, getBillingStats);

router.route('/:id')
  .get(protect, getBillById)
  .put(protect, workerOrAdmin, updateBill);

router.patch('/:id/status', protect, workerOrAdmin, updateBillStatus);

module.exports = router;
