const express = require('express');
const scheduleController = require('../../controllers/schedule.controller');
const authController = require('../../controllers/auth.controller');

const router = express.Router();

router.use(authController.protect);

// Routes for a specific trip
router.route('/trip/:tripId')
  .get(scheduleController.getScheduleForTrip)
  .post(scheduleController.createScheduleItem);

// --- NEW: Routes for updating and deleting a specific item by its ID ---
router.route('/:itemId')
  .patch(scheduleController.updateScheduleItem)
  .delete(scheduleController.deleteScheduleItem);

module.exports = router;
