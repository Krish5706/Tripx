const Schedule = require('../models/schedule.model');
const Trip = require('../models/trip.model');

// --- Controller to get all schedule items for a specific trip ---
exports.getScheduleForTrip = async (req, res) => {
  try {
    const tripId = req.params.tripId;
    const trip = await Trip.findById(tripId);
    if (!trip || trip.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'No trip found.' });
    }
    const scheduleItems = await Schedule.find({ trip: tripId });
    res.status(200).json({
      status: 'success',
      results: scheduleItems.length,
      data: { schedule: scheduleItems },
    });
  } catch (error) {
    res.status(400).json({ status: 'fail', message: error.message });
  }
};

// --- Controller to create a new schedule item ---
exports.createScheduleItem = async (req, res) => {
  try {
    const tripId = req.params.tripId;
    const trip = await Trip.findById(tripId);
    if (!trip || trip.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'No trip found.' });
    }
    const newScheduleItemData = { ...req.body, trip: tripId, user: req.user.id };
    const newScheduleItem = await Schedule.create(newScheduleItemData);
    res.status(201).json({
      status: 'success',
      data: { scheduleItem: newScheduleItem },
    });
  } catch (error) {
    res.status(400).json({ status: 'fail', message: error.message });
  }
};

// --- NEW: Controller to update a schedule item ---
exports.updateScheduleItem = async (req, res) => {
  try {
    const item = await Schedule.findById(req.params.itemId);
    if (!item || item.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Schedule item not found.' });
    }
    const updatedItem = await Schedule.findByIdAndUpdate(req.params.itemId, req.body, {
      new: true,
      runValidators: true,
    });
    res.status(200).json({ status: 'success', data: { item: updatedItem } });
  } catch (error) {
    res.status(400).json({ status: 'fail', message: error.message });
  }
};

// --- NEW: Controller to delete a schedule item ---
exports.deleteScheduleItem = async (req, res) => {
  try {
    const item = await Schedule.findById(req.params.itemId);
    if (!item || item.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Schedule item not found.' });
    }
    await Schedule.findByIdAndDelete(req.params.itemId);
    res.status(204).json({ status: 'success', data: null });
  } catch (error) {
    res.status(400).json({ status: 'fail', message: error.message });
  }
};
