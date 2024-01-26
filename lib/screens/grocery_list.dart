import 'dart:convert';

import 'package:expense_tracker/data/categories.dart';
import 'package:expense_tracker/models/grocery_item.dart';
import 'package:expense_tracker/widgets/new_item.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  // do initialization work, so it loads items when the app just starts
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    // fetching data from Firebase
    final url = Uri.https('shopping-list-a484c-default-rtdb.firebaseio.com',
        'shopping-list.json');


    // if the url is broken, which could be due to a DNS error, server not found, no internet connection
    // they are not "caught" by the if statements inside the try block 
    // because they occur at a lower level (network transport layer) and will triggle catch

    // if the response from the server is successful,
    // but the status code indicates an error (e.g., 400 or above), 
    // it's handled explicitly by setting an error state.
    // it's just an application-level handling of a non-ideal response

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }

      // some database may use status code such as (response.statuscode == 404)
      // but firebase uses 'null'
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // convert json data back to dart format
      // dynamic values because we have 2 strings and 1 integer
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => element.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      // overwrite groceryItems
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Oops! something went wrong. Please try again later.';
      });
    }

    // another way to handle error
    // throw Exception('An error occurerd!);
  }

  // push yields a Future object that holds the data that maybe returned by the screen which you push on the stack of screen
  // push is a generic function so we can give the type to it
  // by using asyc and await, we can recieve the data
  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final itemIndex = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('shopping-list-a484c-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(itemIndex, item);
      });
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Fail to delete the item, please try again later.'),
        ),
      );
    } else {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: const Text('item removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(
              () {
                _groceryItems.insert(itemIndex, item);
              },
            );
          },
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = const Center(
      child: Text('No grocery items found. Start adding some!'),
    );

    if (_isLoading) {
      mainContent = const Center(child: CircularProgressIndicator());
    }

    Widget theList = ListView.builder(
      itemCount: _groceryItems.length,
      itemBuilder: (ctx, index) => Dismissible(
        background: Container(
          color: Theme.of(context).colorScheme.error.withOpacity(0.75),
        ),
        onDismissed: (direction) => _removeItem(_groceryItems[index]),
        key: ValueKey(_groceryItems[index].id),
        child: ListTile(
          title: Text(_groceryItems[index].name),
          leading: Container(
            width: 24,
            height: 24,
            color: _groceryItems[index].category.color,
          ),
          trailing: Text(
            _groceryItems[index].quantity.toString(),
          ),
        ),
      ),
    );

    if (_error != null) {
      mainContent = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Groceries'), actions: [
        IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
      ]),
      body: _groceryItems.isEmpty ? mainContent : theList,

      // check groceryList_FutureBuilder to see how to use FutureBuilder in Scaffold body
      // drawbacks:
      // added item will be send to backend but not displayed until reload the app
      // removing item might cause error
      // there are because the builder in FutureBuild only executes once when the future is created first time
      
    );
  }
}
