const Trip = require('../models/trip.model');

// --- Controller to get all trips for the logged-in user ---
exports.getAllTrips = async (req, res) => {
  try {
    // The user's ID is added to the request object by our 'protect' middleware
    const trips = await Trip.find({ user: req.user.id });

    res.status(200).json({
      status: 'success',
      results: trips.length,
      data: {
        trips,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to create a new trip ---
exports.createTrip = async (req, res) => {
  try {
    // Combine the trip data from the request body with the user's ID
    const newTripData = { ...req.body, user: req.user.id };

    const newTrip = await Trip.create(newTripData);

    res.status(201).json({
      status: 'success',
      data: {
        trip: newTrip,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};
