const express = require('express');
const authController = require('../../controllers/auth.controller');

// Create a new router object
const router = express.Router();

// --- Authentication Routes ---

// Route for user registration
// When a POST request is made to '/register', call the register function from the authController
router.post('/register', authController.register);

// Route for user login
// When a POST request is made to '/login', call the login function from the authController
router.post('/login', authController.login);

// Export the router to be used in other parts of the application
module.exports = router;
