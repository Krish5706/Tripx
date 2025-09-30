const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema({
  // Link to the specific trip this schedule item belongs to
  trip: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Trip',
    required: true,
  },
  // The user who owns this item (for easier queries)
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: [true, 'Please provide a title for the schedule item.'],
    trim: true,
  },
  description: {
    type: String,
    trim: true,
  },
  location: {
    type: String,
    trim: true,
  },
  category: {
    type: String,
    enum: ['Transportation', 'Accommodation', 'Activity', 'Food', 'Other'],
    default: 'Activity',
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High'],
    default: 'Medium',
  },
  startTime: {
    type: Date,
    required: [true, 'Please provide a start time.'],
  },
  endTime: {
    type: Date,
  },
}, {
  timestamps: true,
});

const Schedule = mongoose.model('Schedule', scheduleSchema);

module.exports = Schedule;
