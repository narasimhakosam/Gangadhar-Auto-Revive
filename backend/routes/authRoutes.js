const express = require('express');
const router = express.Router();
const { authUser, registerUser, getUserProfile, getUsers, updateUser, deleteUser } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

router.post('/register', registerUser);
router.post('/login', authUser);
router.get('/profile', protect, getUserProfile);

// User Management Routes
router.route('/')
  .get(protect, getUsers);

router.route('/:id')
  .put(protect, updateUser)
  .delete(protect, deleteUser);

module.exports = router;
