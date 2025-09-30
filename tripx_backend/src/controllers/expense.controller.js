const Expense = require('../models/expense.model');
const Trip = require('../models/trip.model');

// --- Controller to get all expenses for a specific trip ---
exports.getAllExpensesForTrip = async (req, res) => {
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

    const expenses = await Expense.find({ trip: tripId });

    res.status(200).json({
      status: 'success',
      results: expenses.length,
      data: {
        expenses,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to create a new expense ---
exports.createExpense = async (req, res) => {
  try {
    const tripId = req.params.tripId;

    // Security check
    const trip = await Trip.findById(tripId);
    if (!trip || trip.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Trip not found.' });
    }

    const newExpenseData = {
      ...req.body,
      trip: tripId,
      user: req.user.id,
    };

    const newExpense = await Expense.create(newExpenseData);

    res.status(201).json({
      status: 'success',
      data: {
        expense: newExpense,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to update an expense ---
exports.updateExpense = async (req, res) => {
  try {
    const expenseId = req.params.expenseId;

    // Security check: Find the expense and verify the user owns it
    const expense = await Expense.findById(expenseId);
    if (!expense || expense.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Expense not found.' });
    }

    const updatedExpense = await Expense.findByIdAndUpdate(expenseId, req.body, {
      new: true,
      runValidators: true,
    });

    res.status(200).json({
      status: 'success',
      data: {
        expense: updatedExpense,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: 'fail',
      message: error.message,
    });
  }
};

// --- Controller to delete an expense ---
exports.deleteExpense = async (req, res) => {
  try {
    const expenseId = req.params.expenseId;

    // Security check
    const expense = await Expense.findById(expenseId);
    if (!expense || expense.user.toString() !== req.user.id) {
      return res.status(404).json({ status: 'fail', message: 'Expense not found.' });
    }

    await Expense.findByIdAndDelete(expenseId);

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
