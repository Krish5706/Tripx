const PackingListItem = require('../models/packingListItem.model');
const Trip = require('../models/trip.model');

// --- Controller to get all packing list items for a specific trip ---
exports.getPackingListForTrip = async (req, res) => {
  try {
    const tripId = req.params.tripId;

    // Security check: Ensure the trip belongs to the logged-in user
    const trip = await Trip.findById(tripId);
    if (!trip || trip.user.toString() !== req.user.id) {
      return res.status(404).json({
        status: 'fail',
        message: 'No trip found with that ID for the current user.',
      });
    }

    const items = await PackingListItem.find({ trip: tripId });

    res.status(200).json({
      status: 'success',
      results: items.length,
      data: {
        items,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to create a new packing list item ---
exports.createPackingListItem = async (req, res) => {
  try {
    const tripId = req.params.tripId;

    // Security check
    const trip = await Trip.findById(tripId);
    if (!trip || trip.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Trip not found.' });
    }

    const newItemData = {
      ...req.body,
      trip: tripId,
      user: req.user.id,
    };

    const newItem = await PackingListItem.create(newItemData);

    res.status(201).json({
      status: 'success',
      data: {
        item: newItem,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to update a packing list item (e.g., toggle isPacked) ---
exports.updatePackingListItem = async (req, res) => {
  try {
    const itemId = req.params.itemId;

    // Security check: Find the item and verify the user owns it
    const item = await PackingListItem.findById(itemId);
    if (!item || item.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Item not found.' });
    }

    // Update the item with the data from the request body
    const updatedItem = await PackingListItem.findByIdAndUpdate(itemId, req.body, {
      new: true, // Return the updated document
      runValidators: true,
    });

    res.status(200).json({
      status: 'success',
      data: {
        item: updatedItem,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to delete a packing list item ---
exports.deletePackingListItem = async (req, res) => {
  try {
    const itemId = req.params.itemId;

    // Security check
    const item = await PackingListItem.findById(itemId);
    if (!item || item.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Item not found.' });
    }

    await PackingListItem.findByIdAndDelete(itemId);

    res.status(204).json({
      status: 'success',
      data: null,
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};
