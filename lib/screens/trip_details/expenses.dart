import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripx/services/expense_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final List<Color> _chartColors = []; // Non-final due to dynamic addition

  Future<void> _addExpense() async {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final category = _categoryController.text.trim();
    if (description.isNotEmpty && amount > 0 && category.isNotEmpty) {
      await _expenseService.addExpense(description, amount, category);
      if (mounted) {
        setState(() {});
        _descriptionController.clear();
        _amountController.clear();
        _categoryController.clear();
      }
    }
  }

  Future<void> _editExpenseDialog(Expense expense) async {
    _descriptionController.text = expense.description;
    _amountController.text = expense.amount.toString();
    _categoryController.text = expense.category;

    if (!mounted) return;

    final dialogResult = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final description = _descriptionController.text.trim();
              final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
              final category = _categoryController.text.trim();
              if (description.isNotEmpty && amount > 0 && category.isNotEmpty) {
                await _expenseService.updateExpense(expense.id, description, amount, category);
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (mounted && dialogResult == true) {
      setState(() {});
      _descriptionController.clear();
      _amountController.clear();
      _categoryController.clear();
    }
  }

  Future<void> _confirmDelete(Expense expense) async {
    if (!mounted) return;

    final dialogResult = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _expenseService.deleteExpense(expense.id);
              Navigator.pop(dialogContext, true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (mounted && dialogResult == true) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  Map<String, double> _calculateCategoryTotals(List<Expense> expenses) {
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categoryTotals;
  }

  List<Color> _generateColors(int count) {
    const predefinedColors = [
      Color(0xFF2196F3), // Blue
      Color(0xFFF44336), // Red
      Color(0xFF4CAF50), // Green
      Color(0xFFFFC107), // Amber
      Color(0xFF9C27B0), // Purple
      Color(0xFF00BCD4), // Cyan
      Color(0xFFE91E63), // Pink
      Color(0xFF3F51B5), // Indigo
    ];

    if (_chartColors.length >= count) {
      return _chartColors.sublist(0, count);
    }
    final needed = count - _chartColors.length;
    final newColors = List<Color>.generate(
      needed,
      (index) => predefinedColors[index % predefinedColors.length],
    );
    _chartColors.addAll(newColors);
    return _chartColors.sublist(0, count);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: const Color.fromARGB(255, 44, 154, 244),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardColor,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _descriptionController,
                          style: TextStyle(color: textColor, fontSize: screenWidth * 0.04),
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor, fontSize: screenWidth * 0.04),
                          decoration: InputDecoration(
                            labelText: 'Amount (₹)',
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        TextField(
                          controller: _categoryController,
                          style: TextStyle(color: textColor, fontSize: screenWidth * 0.04),
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        ElevatedButton(
                          onPressed: _addExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 39, 153, 240),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                            minimumSize: Size(double.infinity, 0),
                          ),
                          child: Text(
                            'Add Expense',
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardColor,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Distribution',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final chartSize = isLandscape
                                ? min(constraints.maxWidth * 0.9, screenHeight * 0.7)
                                : min(constraints.maxWidth * 0.9, screenHeight * 0.3);
                            return Container(
                              height: chartSize,
                              width: constraints.maxWidth,
                              alignment: Alignment.center,
                              child: FutureBuilder<List<Expense>>(
                                future: _expenseService.getExpenses(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Error loading chart: ${snapshot.error}',
                                        style: TextStyle(color: secondaryTextColor, fontSize: screenWidth * 0.04),
                                      ),
                                    );
                                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No expenses to display in chart',
                                        style: TextStyle(color: secondaryTextColor, fontSize: screenWidth * 0.04),
                                      ),
                                    );
                                  }
                                  final categoryTotals = _calculateCategoryTotals(snapshot.data!);
                                  if (categoryTotals.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No categories to display',
                                        style: TextStyle(color: secondaryTextColor, fontSize: screenWidth * 0.04),
                                      ),
                                    );
                                  }
                                  final colors = _generateColors(categoryTotals.length);
                                  final sections = categoryTotals.entries.toList().asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final mapEntry = entry.value;
                                    return PieChartSectionData(
                                      value: mapEntry.value,
                                      title: '${mapEntry.key}\n₹${mapEntry.value.toStringAsFixed(2)}',
                                      color: colors[index % colors.length],
                                      radius: chartSize * 0.35,
                                      titleStyle: TextStyle(
                                        fontSize: isLandscape ? screenWidth * 0.025 : screenWidth * 0.03,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black54,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      titlePositionPercentageOffset: 0.55,
                                    );
                                  }).toList();

                                  return SizedBox(
                                    width: chartSize,
                                    height: chartSize,
                                    child: PieChart(
                                      PieChartData(
                                        sections: sections,
                                        sectionsSpace: 2,
                                        centerSpaceRadius: chartSize * 0.15,
                                        borderData: FlBorderData(show: false),
                                        pieTouchData: PieTouchData(enabled: true),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardColor,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        FutureBuilder<List<Expense>>(
                          future: _expenseService.getExpenses(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(color: textColor, fontSize: screenWidth * 0.04),
                                ),
                              );
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      size: screenWidth * 0.2,
                                      color: secondaryTextColor,
                                    ),
                                    SizedBox(height: screenHeight * 0.015),
                                    Text(
                                      'No expenses yet.\nTrack your trip costs!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: screenWidth * 0.04,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              final expenses = snapshot.data!;
                              return Column(
                                children: expenses.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final expense = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: index < expenses.length - 1 ? screenHeight * 0.01 : 0),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      color: cardColor,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.all(screenWidth * 0.04),
                                        title: Text(
                                          expense.description,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '₹${expense.amount.toStringAsFixed(2)} - ${expense.category}',
                                              style: TextStyle(
                                                color: secondaryTextColor,
                                                fontSize: screenWidth * 0.035,
                                              ),
                                            ),
                                            Text(
                                              'Added: ${_formatDate(expense.timestamp)}',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                                fontSize: screenWidth * 0.03,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () => _editExpenseDialog(expense),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red[400],
                                            size: screenWidth * 0.06,
                                          ),
                                          onPressed: () => _confirmDelete(expense),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Expense {
  final int id;
  final String description;
  final double amount;
  final String category;
  final DateTime timestamp;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.timestamp,
  });
}