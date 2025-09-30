const express = require('express');
const destinationController = require('../../controllers/destination.controller');
const authController = require('../../controllers/auth.controller');

const router = express.Router();

// @route   GET /api/destinations
// @desc    Get destination ideas (seasonal or search)
// @access  Public
router.get('/', destinationController.getDestinationIdeas);


// @route   POST /api/destinations
// @desc    Create a new destination
// @access  Private/Admin (We can add an admin role check later)
router.post(
    '/',
    authController.protect, // Ensure user is logged in
    destinationController.createDestination
);

module.exports = router;

