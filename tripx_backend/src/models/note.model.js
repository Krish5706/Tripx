const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
  // Link to the specific trip this note belongs to
  trip: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Trip',
    required: true,
  },
  // The user who owns this note
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  // The title of the note
  title: {
    type: String,
    required: [true, 'Please provide a title for the note.'],
    trim: true,
  },
  // The main content of the note
  content: {
    type: String,
    trim: true,
  },
  // --- NEW: For color-coding notes ---
  color: {
    type: String,
    default: '#FFFFFF', // Default to white
  },
}, {
  timestamps: true,
});

const Note = mongoose.model('Note', noteSchema);

module.exports = Note;
