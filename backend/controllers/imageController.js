const Image = require('../models/Image');
const Vehicle = require('../models/Vehicle');

// @desc    Upload new image (Base64)
// @route   POST /api/images
// @access  Private (Worker/Admin)
const uploadImage = async (req, res) => {
  try {
    const { vehicleId, visitId, base64Data } = req.body;

    if (!base64Data) {
      return res.status(400).json({ message: 'No image data provided' });
    }

    const image = await Image.create({
      vehicle: vehicleId,
      visit: visitId,
      base64Data,
      uploadedBy: req.user._id
    });

    if (visitId) {
      const vehicle = await Vehicle.findById(vehicleId);
      if (vehicle) {
        const visit = vehicle.visits.id(visitId);
        if (visit) {
           visit.images.push(image._id);
           await vehicle.save();
        }
      }
    }

    res.status(201).json(image);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get image by ID
// @route   GET /api/images/:id
// @access  Private
const getImageById = async (req, res) => {
  try {
     const image = await Image.findById(req.params.id);

     if (!image) {
       return res.status(404).json({ message: 'Image not found' });
     }

     res.json(image);
  } catch (error) {
     res.status(500).json({ message: error.message });
  }
};

module.exports = {
  uploadImage,
  getImageById
};
