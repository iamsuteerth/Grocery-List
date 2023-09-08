import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:http/http.dart' as http;
// import 'package:shopping_app/data/dummy_items.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItemList = [];
  var isLoading = true;
  String? error; // Maybe NULL, otherwise string
  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    final url = Uri.https('backend-url',
        'shopping-list.json');
    // Must be prepared for worst case scenarios such as firebase servers being down
    // > 400 status code, you have a problem
    // Example of implementing try catch
    try {
      final response = await http.get(url);
      if (response.body == 'null') {
        // Backend specific : Firebase returns string 'null' if there is no data from the backend
        setState(() {
          isLoading = false;
        });
        return;
      }
      if (response.statusCode >= 400) {
        setState(() {
          error =
              'Something went wrong while fetching data!\nPlease Try Again Later';
        });
      }
      final Map<String, dynamic> gettedData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in gettedData.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => element.value.title == item.value['category'])
            .value;
        // Yield first match
        // search the categories entries and search for first match where element refers to item in the categories list and it matches the category of item.value['category']
        // We get map entry, so we need to chain a .value
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['qty'],
            category: category,
          ),
        );
        // Possible error in  Map<String, Map<String,dynamic>> which is too specific for dart should be replaced with Map<String, dynamic>
        // Another possible error is getting NULL if there are no items in the backend
      }
      setState(() {
        _groceryItemList = loadedItems;
        isLoading = false;
      });
    } catch (errorException) {
      setState(() {
        error = 'Something went wrong\nPlease Try Again Later';
      });
    }
  }

  void addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: ((context) => const NewItem()),
      ),
    );
    if (newItem == null) return;
    setState(() {
      _groceryItemList.add(newItem);
    });
  }

  void removeItem(GroceryItem item) async {
    final index = _groceryItemList.indexOf(item);
    setState(() {
      _groceryItemList.removeWhere((element) => element.id == item.id);
    });
    final url = Uri.https('backend-url',
        'shopping-list/${item.id}.json');
    // Targeting a specific id
    final response = await http.delete(url);
    // We don't need await for this as we can immediately remove the item even if it getting removed from the backend
    if (response.statusCode >= 400) {
      // In case an error
      setState(() {
        _groceryItemList.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No items added!',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
    if (isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItemList.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItemList.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItemList[index].id),
          onDismissed: (direction) {
            removeItem(_groceryItemList[index]);
          },
          child: ListTile(
            title: Text(_groceryItemList[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItemList[index].category.color,
            ),
            trailing: Text(
              _groceryItemList[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    if (error != null) {
      content = Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error!,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: content,
    );
  }
}
