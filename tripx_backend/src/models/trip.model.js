const mongoose = require('mongoose');

// Define the schema for the Trip model
const tripSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // UPDATED: More descriptive field for the trip's title
    tripName: {
      type: String,
      required: [true, 'Please provide a trip name'],
      trim: true,
    },
    destination: {
      type: String,
      required: [true, 'Please provide a destination'],
      trim: true,
    },
    // NEW: Field for a longer trip description
    description: {
      type: String,
      trim: true,
      default: '',
    },
    startDate: {
      type: Date,
      required: [true, 'Please provide a start date'],
    },
    endDate: {
      type: Date,
      required: [true, 'Please provide an end date'],
    },
    // NEW: Field for the trip's estimated budget
    budget: {
      type: Number,
    },
    // NEW: Field to store a list of planned activities
    activities: {
      type: [String],
      default: [],
    },
    coverImage: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

const Trip = mongoose.model('Trip', tripSchema);

module.exports = Trip;
