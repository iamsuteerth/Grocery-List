import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widgets/new_item.dart';

/*
 * NOTE : Only to demonstrate FUTURE BUILDER and how we can handle states ELEGANTLY
 */
class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  // ignore: prefer_final_fields
  List<GroceryItem> _groceryItemList = [];
  late Future<List<GroceryItem>> loadedItems;
  String? error;
  @override
  void initState() {
    super.initState();
    loadedItems = loadItems();
  }

  Future<List<GroceryItem>> loadItems() async {
    final url = Uri.https('backend-url',
        'shopping-list.json');
    final response = await http.get(url);
    if (response.body == 'null') {
      return [];
    }
    if (response.statusCode >= 400) {
      throw Exception(
          'Failed to fetch data. PLease try again later'); // To make has error true
      // setState(() {
      //   error =
      //       'Something went wrong while fetching data!\nPlease Try Again Later';
      // });
    }
    final Map<String, dynamic> gettedData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in gettedData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['qty'],
          category: category,
        ),
      );
    }
    return loadedItems;
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
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItemList.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder(
        // Executed only once when Future is created
        future: loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading state
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No items added!',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              key: ValueKey(snapshot.data![index].id),
              onDismissed: (direction) {
                removeItem(snapshot.data![index]);
              },
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
