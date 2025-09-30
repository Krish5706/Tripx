const express = require('express');
const noteController = require('../../controllers/note.controller');
const authController = require('../../controllers/auth.controller');

const router = express.Router();

// Protect all routes in this file, ensuring only logged-in users can access them.
router.use(authController.protect);

// --- Routes for getting the list and creating a new item for a specific trip ---
router.route('/trip/:tripId')
  .get(noteController.getAllNotesForTrip)
  .post(noteController.createNote);

// --- Routes for updating and deleting a specific note by its own ID ---
router.route('/:noteId')
  .patch(noteController.updateNote)
  .delete(noteController.deleteNote);

module.exports = router;
