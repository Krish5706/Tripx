const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema({
  trip: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Trip',
    required: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  description: {
    type: String,
    required: [true, 'Please provide a description.'],
    trim: true,
  },
  amount: {
    type: Number,
    required: [true, 'Please provide an amount.'],
  },
  category: {
    type: String,
    required: [true, 'Please provide a category.'],
    trim: true,
    default: 'Miscellaneous',
  },
  date: {
    type: Date,
    default: Date.now,
  },
  // --- NEW: For multi-currency support ---
  currency: {
    type: String,
    default: 'INR', // Default to Indian Rupees
  },
}, {
  timestamps: true,
});

const Expense = mongoose.model('Expense', expenseSchema);

module.exports = Expense;
