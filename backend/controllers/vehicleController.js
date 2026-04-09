const Vehicle = require('../models/Vehicle');

// @desc    Get all vehicles (or search)
// @route   GET /api/vehicles
// @access  Private
const getVehicles = async (req, res) => {
  try {
    const { search } = req.query;
    let query = {};
    if (search) {
      query.registrationNumber = { $regex: search, $options: 'i' };
    }
    
    // Customers can only see their own vehicles
    if (req.user.role === 'Customer') {
      query.user = req.user._id;
    }

    const vehicles = await Vehicle.find(query).sort({ updatedAt: -1 });
    res.json(vehicles);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get single vehicle by ID or Registration Number
// @route   GET /api/vehicles/:id
// @access  Private
const getVehicleById = async (req, res) => {
  try {
     const vehicle = await Vehicle.findById(req.params.id)
       .populate('visits.worker', 'name')
       .populate({ path: 'visits.bill', select: 'total isGstEnabled' })
       .populate({ path: 'visits.images', select: '_id' }); 

     if (!vehicle) {
       return res.status(404).json({ message: 'Vehicle not found' });
     }

     // Security check
     if (req.user.role === 'Customer' && vehicle.user?.toString() !== req.user._id.toString()) {
        return res.status(401).json({ message: 'Not authorized to view this vehicle' });
     }

     res.json(vehicle);
  } catch (error) {
     res.status(500).json({ message: error.message });
  }
};

// @desc    Create a new vehicle
// @route   POST /api/vehicles
// @access  Private (Worker/Admin)
const createVehicle = async (req, res) => {
  try {
    const { registrationNumber, model, ownerName, ownerPhone, userId } = req.body;

    const exists = await Vehicle.findOne({ registrationNumber });
    if (exists) {
       return res.status(400).json({ message: 'Vehicle already exists' });
    }

    const vehicle = await Vehicle.create({
      registrationNumber,
      model,
      ownerName,
      ownerPhone,
      user: userId || null
    });

    res.status(201).json(vehicle);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add visit to vehicle
// @route   POST /api/vehicles/:id/visits
// @access  Private (Worker/Admin)
const addVehicleVisit = async (req, res) => {
  try {
     const { description, parts, labourCharge, images } = req.body;

     const vehicle = await Vehicle.findById(req.params.id);
     if (!vehicle) {
        return res.status(404).json({ message: 'Vehicle not found' });
     }

     const visit = {
       description,
       worker: req.user._id,
       parts,
       labourCharge,
       images: images || [],
       date: new Date()
     };

     vehicle.visits.unshift(visit); // Add latest first
     await vehicle.save();

     res.status(201).json(vehicle.visits[0]); 
  } catch (error) {
     res.status(500).json({ message: error.message });
  }
};

// @desc    Update vehicle details
// @route   PUT /api/vehicles/:id
// @access  Private (Worker/Admin)
const updateVehicle = async (req, res) => {
  try {
    const { model, ownerName, ownerPhone } = req.body;

    const vehicle = await Vehicle.findByIdAndUpdate(
      req.params.id,
      { model, ownerName, ownerPhone },
      { new: true }
    );

    if (!vehicle) {
      return res.status(404).json({ message: 'Vehicle not found' });
    }

    res.json(vehicle);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getVehicles,
  getVehicleById,
  createVehicle,
  updateVehicle,
  addVehicleVisit
};
