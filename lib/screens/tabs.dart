import 'package:expense_tracker/screens/expenses.dart';
import 'package:expense_tracker/screens/grocery_list.dart';
import 'package:flutter/material.dart';

class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
      ),
      body: Column(children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const Expenses(),
              ),
            );
          },
          child: const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined),
              Text('Expense Tracker'),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const GroceryList(),
              ),
            );
          },
          child: const Row(
            children: [
              Icon(Icons.shopping_cart),
              Text('Shopping List'),
            ],
          ),
        ),
      ]),
    );
  }
}
