const express = require('express');
const expenseController = require('../../controllers/expense.controller');
const authController = require('../../controllers/auth.controller');

const router = express.Router();

// Protect all routes in this file, ensuring only logged-in users can access them.
router.use(authController.protect);

// --- Routes for getting the list and creating a new item for a specific trip ---
router.route('/trip/:tripId')
  .get(expenseController.getAllExpensesForTrip)
  .post(expenseController.createExpense);

// --- Routes for updating and deleting a specific expense by its own ID ---
router.route('/:expenseId')
  .patch(expenseController.updateExpense)
  .delete(expenseController.deleteExpense);

module.exports = router;
