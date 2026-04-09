const express = require('express');
const router = express.Router();
const { uploadImage, getImageById } = require('../controllers/imageController');
const { protect, workerOrAdmin } = require('../middleware/authMiddleware');

router.route('/')
  .post(protect, workerOrAdmin, uploadImage);

router.route('/:id')
  .get(protect, getImageById);

module.exports = router;
