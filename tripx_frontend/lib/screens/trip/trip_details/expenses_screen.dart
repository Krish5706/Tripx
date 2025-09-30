import 'package:flutter/material.dart';
import 'package:tripx_frontend/models/expense.dart';
import 'package:tripx_frontend/models/trip.dart';
import 'package:tripx_frontend/repositories/expense_repository.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late Future<List<Expense>> _expensesFuture;
  final ExpenseRepository _repository = ExpenseRepository();
  late Trip _trip;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trip = ModalRoute.of(context)!.settings.arguments as Trip;
    _expensesFuture = _fetchExpenses();
  }

  Future<List<Expense>> _fetchExpenses() async {
    return _repository.getExpensesForTrip(_trip.id);
  }

  void _refreshExpenses() {
    setState(() {
      _expensesFuture = _fetchExpenses();
    });
  }

  void _showAddOrEditExpenseDialog({Expense? expense}) {
    showDialog(
      context: context,
      builder: (context) => _AddExpenseDialog(
        tripId: _trip.id,
        expense: expense,
        onSave: _refreshExpenses,
      ),
    );
  }

  void _deleteExpense(String expenseId) async {
    await _repository.deleteExpense(expenseId);
    _refreshExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expenses for ${_trip.tripName}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme);
          }

          final expenses = snapshot.data!;
          final totalSpent = expenses.fold<double>(0, (sum, item) => sum + item.amount);
          final budget = _trip.budget ?? 0;
          final remaining = budget - totalSpent;
          final groupedExpenses = groupBy(expenses, (Expense item) => DateFormat.yMMMd().format(item.date));

          return Column(
            children: [
              _buildBudgetSummary(context, budget, totalSpent, remaining, expenses),
              Expanded(
                child: ListView.builder(
                  itemCount: groupedExpenses.keys.length,
                  itemBuilder: (context, index) {
                    final date = groupedExpenses.keys.elementAt(index);
                    final itemsForDate = groupedExpenses[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                          child: Text(
                            date,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        ...itemsForDate.map((item) => _ExpenseListItem(
                              expense: item,
                              onEdit: () => _showAddOrEditExpenseDialog(expense: item),
                              onDelete: () => _deleteExpense(item.id),
                            )).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditExpenseDialog(),
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetSummary(BuildContext context, double budget, double spent, double remaining, List<Expense> expenses) {
    final theme = Theme.of(context);
    final double spentPercentage = budget > 0 ? (spent / budget).clamp(0, 1) : 0;
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Budget Overview',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  sections: categoryTotals.entries.map((entry) {
                    return PieChartSectionData(
                      color: _getColorForCategory(entry.key),
                      value: entry.value,
                      title: '${(entry.value / spent * 100).toStringAsFixed(0)}%',
                      radius: 40,
                      titleStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBudgetColumn(theme, 'Budget', currencyFormat.format(budget), theme.colorScheme.primary),
                _buildBudgetColumn(theme, 'Spent', currencyFormat.format(spent), theme.colorScheme.error),
                _buildBudgetColumn(theme, 'Remaining', currencyFormat.format(remaining), theme.colorScheme.tertiary),
              ],
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: spentPercentage,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetColumn(ThemeData theme, String title, String amount, Color color) {
    return Column(
      children: [
        Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 80, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 24),
          Text(
            'No expenses recorded yet.',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "+" button to add your first expense.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseListItem({required this.expense, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(_getIconForCategory(expense.category), color: theme.colorScheme.onSecondaryContainer),
      ),
      title: Text(
        expense.description,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        expense.category,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currencyFormat.format(expense.amount),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// --- UPDATED DIALOG WIDGET ---
class _AddExpenseDialog extends StatefulWidget {
  final String tripId;
  final Expense? expense;
  final VoidCallback onSave;

  const _AddExpenseDialog({required this.tripId, this.expense, required this.onSave});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final ExpenseRepository _repository = ExpenseRepository();

  final List<String> _defaultCategories = [
    'Food',
    'Transportation',
    'Accommodation',
    'Activity',
    'Miscellaneous',
    'Other...'
  ];
  String? _selectedCategory;
  bool _showCustomCategoryField = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _descriptionController.text = widget.expense!.description;
      _amountController.text = widget.expense!.amount.toString();
      // Check if the existing category is one of the defaults
      if (_defaultCategories.contains(widget.expense!.category)) {
        _selectedCategory = widget.expense!.category;
      } else {
        _selectedCategory = 'Other...';
        _customCategoryController.text = widget.expense!.category;
        _showCustomCategoryField = true;
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _saveItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        String finalCategory;
        if (_showCustomCategoryField) {
          finalCategory = _customCategoryController.text;
        } else {
          finalCategory = _selectedCategory!;
        }

        if (widget.expense == null) {
          await _repository.createExpense(
            tripId: widget.tripId,
            description: _descriptionController.text,
            amount: double.parse(_amountController.text),
            category: finalCategory,
            date: DateTime.now(),
          );
        } else {
          await _repository.updateExpense(
            expenseId: widget.expense!.id,
            description: _descriptionController.text,
            amount: double.parse(_amountController.text),
            category: finalCategory,
          );
        }
        widget.onSave();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save expense: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        widget.expense == null ? 'Add New Expense' : 'Edit Expense',
        style: theme.textTheme.headlineSmall,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: Text('Select Category', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _defaultCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: theme.textTheme.bodyLarge),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    _showCustomCategoryField = newValue == 'Other...';
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              if (_showCustomCategoryField)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _customCategoryController,
                    decoration: InputDecoration(
                      labelText: 'New Category Name',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (_showCustomCategoryField && (value == null || value.isEmpty)) {
                        return 'Please enter a category name';
                      }
                      return null;
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveItem,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

IconData _getIconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return Icons.fastfood_outlined;
    case 'transportation':
      return Icons.directions_bus_outlined;
    case 'accommodation':
      return Icons.hotel_outlined;
    case 'activity':
      return Icons.local_activity_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}

Color _getColorForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return Colors.orange;
    case 'transportation':
      return Colors.blue;
    case 'accommodation':
      return Colors.purple;
    case 'activity':
      return Colors.green;
    default:
      return Colors.grey;
  }
}