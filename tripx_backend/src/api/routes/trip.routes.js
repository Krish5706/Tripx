const express = require('express');
const tripController = require('../../controllers/trip.controller');
const authController = require('../../controllers/auth.controller'); // We need this for the protect middleware

const router = express.Router();

// --- Protect all routes after this middleware ---
// This line ensures that a user must be logged in to access any of the trip routes.
// The 'protect' middleware will verify the JWT token and attach the user to the request object.
router.use(authController.protect);

// --- Trip Routes ---

// Route to get all trips for the logged-in user and to create a new trip
router
  .route('/')
  .get(tripController.getAllTrips)
  .post(tripController.createTrip);

// We can add routes for specific trips (e.g., getting one trip, updating, deleting) later
// router
//   .route('/:id')
//   .get(tripController.getTrip)
//   .patch(tripController.updateTrip)
//   .delete(tripController.deleteTrip);

module.exports = router;
