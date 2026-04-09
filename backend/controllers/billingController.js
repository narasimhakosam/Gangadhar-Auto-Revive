const Bill = require('../models/Bill');
const Vehicle = require('../models/Vehicle');
const Counter = require('../models/Counter');

// @desc    Create a new bill
// @route   POST /api/billing
// @access  Private (Worker/Admin)
// @desc    Get bill by ID
// @route   GET /api/billing/:id
// @access  Private
const getBillById = async (req, res) => {
  try {
     const bill = await Bill.findById(req.params.id)
       .populate('vehicle', 'registrationNumber model ownerName ownerPhone visits')
       .populate('worker', 'name');

     if (!bill) {
       return res.status(404).json({ message: 'Bill not found' });
     }

     // Manually find the visit in the vehicle's visits array
     let billData = bill.toObject();
     const vehicle = await Vehicle.findById(bill.vehicle._id);
     if (vehicle && bill.visit) {
       const visit = vehicle.visits.id(bill.visit);
       if (visit) {
         billData.visit = visit;
       }
     }

     res.json(billData);
  } catch (error) {
     res.status(500).json({ message: error.message });
  }
};

const createBill = async (req, res) => {
  try {
    const { vehicleId, visitId, items, labourCharge, isGstEnabled } = req.body;

    // Calculate totals
    let subTotal = labourCharge || 0;
    const processedItems = items.map(item => {
      const itemTotal = item.quantity * item.unitPrice;
      subTotal += itemTotal;
      return {
        ...item,
        totalPrice: itemTotal
      };
    });

    let gstAmount = 0;
    if (isGstEnabled) {
      gstAmount = subTotal * 0.18; // 18% GST
    }

    const total = subTotal + gstAmount;

    const bill = await Bill.create({
      vehicle: vehicleId,
      visit: visitId,
      worker: req.user._id,
      items: processedItems,
      labourCharge: labourCharge || 0,
      subTotal,
      isGstEnabled,
      gstAmount,
      total
    });

    // Update vehicle visit with bill reference
    const vehicle = await Vehicle.findById(vehicleId);
    if (vehicle) {
      const visit = vehicle.visits.id(visitId);
      if (visit) {
        visit.bill = bill._id;
        await vehicle.save();
      }
    }

    res.status(201).json(bill);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all bills (with status filter)
// @route   GET /api/billing
// @access  Private
const getBills = async (req, res) => {
  try {
    const { status } = req.query;
    let query = {};
    if (status) {
      if (status === 'Pending') {
        // Include bills where status is Pending OR missing
        query = { $or: [{ status: 'Pending' }, { status: { $exists: false } }] };
      } else {
        query.status = status;
      }
    }

    const bills = await Bill.find(query)
      .populate('vehicle', 'registrationNumber model ownerName ownerPhone')
      .populate('worker', 'name')
      .sort({ createdAt: -1 });

    res.json(bills);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get billing statistics for dashboard
// @route   GET /api/billing/stats
// @access  Private (Admin)
const getBillingStats = async (req, res) => {
  try {
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    const pendingStats = await Bill.aggregate([
      { $match: { $or: [{ status: 'Pending' }, { status: { $exists: false } }] } },
      { $group: { _id: null, total: { $sum: '$total' }, count: { $sum: 1 } } }
    ]);

    const todayReceivedStats = await Bill.aggregate([
      { 
        $match: { 
          status: 'Completed', 
          completedAt: { $gte: startOfToday, $lte: endOfToday } 
        } 
      },
      { $group: { _id: null, total: { $sum: '$total' }, count: { $sum: 1 } } }
    ]);

    const result = {
      Pending: {
        total: pendingStats[0]?.total || 0,
        count: pendingStats[0]?.count || 0
      },
      TodayReceived: {
        total: todayReceivedStats[0]?.total || 0,
        count: todayReceivedStats[0]?.count || 0
      }
    };

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};



// @desc    Update bill status (e.g., mark as Completed)
// @route   PATCH /api/billing/:id/status
// @access  Private (Admin/Worker)
// @desc    Update an existing bill
// @route   PUT /api/billing/:id
// @access  Private (Worker/Admin)
const updateBill = async (req, res) => {
  try {
    const { items, labourCharge, isGstEnabled, description } = req.body;
    
    // Calculate totals
    let subTotal = labourCharge || 0;
    const processedItems = items.map(item => {
      const itemTotal = item.quantity * item.unitPrice;
      subTotal += itemTotal;
      return {
        ...item,
        totalPrice: itemTotal
      };
    });

    let gstAmount = 0;
    if (isGstEnabled) {
      gstAmount = subTotal * 0.18;
    }

    const total = subTotal + gstAmount;

    const bill = await Bill.findByIdAndUpdate(
      req.params.id,
      {
        items: processedItems,
        labourCharge: labourCharge || 0,
        subTotal,
        isGstEnabled,
        gstAmount,
        total
      },
      { new: true }
    );

    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    // Update visit description if provided
    if (description && bill.vehicle && bill.visit) {
      const vehicle = await Vehicle.findById(bill.vehicle);
      if (vehicle) {
        const visit = vehicle.visits.id(bill.visit);
        if (visit) {
          visit.description = description;
          await vehicle.save();
        }
      }
    }

    res.json(bill);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateBillStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (!['Pending', 'Completed'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const updateData = { status };
    if (status === 'Completed') {
      updateData.completedAt = Date.now();
    }

    const bill = await Bill.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    );

    if (!bill) {
      return res.status(404).json({ message: 'Bill not found' });
    }

    res.json(bill);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createBill,
  getBillById,
  getBills,
  getBillingStats,
  updateBill,
  updateBillStatus
};

