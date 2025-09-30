const Note = require('../models/note.model');
const Trip = require('../models/trip.model');

// --- Controller to get all notes for a specific trip ---
exports.getAllNotesForTrip = async (req, res) => {
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

    const notes = await Note.find({ trip: tripId });

    res.status(200).json({
      status: 'success',
      results: notes.length,
      data: {
        notes,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to create a new note ---
exports.createNote = async (req, res) => {
  try {
    const tripId = req.params.tripId;

    // Security check
    const trip = await Trip.findById(tripId);
    if (!trip || trip.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Trip not found.' });
    }

    const newNoteData = {
      ...req.body, // This will include title, content, and color from the app
      trip: tripId,
      user: req.user.id,
    };

    const newNote = await Note.create(newNoteData);

    res.status(201).json({
      status: 'success',
      data: {
        note: newNote,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to update a note ---
exports.updateNote = async (req, res) => {
  try {
    const noteId = req.params.noteId;

    // Security check: Find the note and verify the user owns it
    const note = await Note.findById(noteId);
    if (!note || note.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Note not found.' });
    }

    const updatedNote = await Note.findByIdAndUpdate(noteId, req.body, {
      new: true,
      runValidators: true,
    });

    res.status(200).json({
      status: 'success',
      data: {
        note: updatedNote,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to delete a note ---
exports.deleteNote = async (req, res) => {
  try {
    const noteId = req.params.noteId;

    // Security check
    const note = await Note.findById(noteId);
    if (!note || note.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Note not found.' });
    }

    await Note.findByIdAndDelete(noteId);

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
