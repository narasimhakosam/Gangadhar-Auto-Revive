const express = require('express');
const router = express.Router();
const {
  getVehicles,
  getVehicleById,
  createVehicle,
  updateVehicle,
  addVehicleVisit
} = require('../controllers/vehicleController');
const { protect, workerOrAdmin } = require('../middleware/authMiddleware');

router.route('/')
  .get(protect, getVehicles)
  .post(protect, workerOrAdmin, createVehicle);

router.route('/:id')
  .get(protect, getVehicleById)
  .put(protect, workerOrAdmin, updateVehicle);

router.post('/:id/visits', protect, workerOrAdmin, addVehicleVisit);

module.exports = router;
