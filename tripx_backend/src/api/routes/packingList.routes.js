const express = require('express');
const packingListController = require('../../controllers/packingList.controller');
const authController = require('../../controllers/auth.controller');

const router = express.Router();

// Protect all routes in this file, ensuring only logged-in users can access them.
router.use(authController.protect);

// --- Routes for getting the list and creating a new item for a specific trip ---
router.route('/trip/:tripId')
  .get(packingListController.getPackingListForTrip)
  .post(packingListController.createPackingListItem);

// --- Routes for updating and deleting a specific item by its own ID ---
router.route('/:itemId')
  .patch(packingListController.updatePackingListItem)
  .delete(packingListController.deletePackingListItem);

module.exports = router;
