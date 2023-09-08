import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/category.dart';
// import 'package:shopping_app/models/grocery_item.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});
  @override
  State<NewItem> createState() {
    return NewItemState();
  }
}

class NewItemState extends State<NewItem> {
  var enteredName = '';
  var enteredQty = 1;
  var selectedCategory = categories[Categories.vegetables];
  final formKey = GlobalKey<FormState>();
  var isSending = false;
  // Can be used as a value for key parameter in underlying widget

  // The state change won't change the key value upon rebuild
  // GlobalKey is generic so FormState (What form widget gives under the hood) to get type checking and auto completion suggestions

  final url = Uri.https(
      'backend-url', 'shopping-list.json');

  Future<void> pushData() async {
    http.Response resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': enteredName,
        'qty': enteredQty,
        'category': selectedCategory!.title,
      }),
    );

    final Map<String, dynamic> response = json.decode(resp.body);

    // By default firebase returns name : unique id it created
    // print(resp.statusCode);
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop(
      GroceryItem(
        id: response['name'],
        name: enteredName,
        quantity: enteredQty,
        category: selectedCategory!,
      ),
    ); // Before we POP, we check if the original widget is even mounted or not
  }

  void saveItem() {
    if (formKey.currentState!.validate()) {
      // Method called on all formfields, because of this only we use formfield and forms

      formKey.currentState!.save();
      setState(() {
        isSending = true;
      });
      pushData();

      // URL, HOW data we are sending will be formatted, DATA
      // We don't need to send ID because firebase will DO that for US

      // Navigator.of(context).pop(
      //   GroceryItem(
      //       id: DateTime.now().toString(),
      //       name: enteredName,
      //       quantity: enteredQty,
      //       category: selectedCategory!),
      // );
    }
  }

  void resetForm() {
    formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  // Triggered to run a validation logic and return an error message if validation fails
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length < 2 ||
                      value.trim().length > 50) {
                    return 'Must be between 2 and 50 chars';
                  }
                  return null;
                },
                onSaved: (value) {
                  // We don't need to change state, thus don't need to call set state
                  enteredName = value!;
                },
              ), // Should be used instead of TextFormField
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Qty'),
                      ),
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Enter valid positive number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        enteredQty = int.parse(value!);
                      },
                    ),
                  ), // Qty
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category
                                .value, // Which value is assigned is assigned to every drop down menu item availble in onchanged function when
                            // user picks a different dropdown item
                            child: Row(
                              // Display fitting drop down menu items
                              children: [
                                Container(
                                  height: 16,
                                  width: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 8),
                                Text(category.value.title),
                              ],
                            ),
                          )
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      }, // Gets value of category as input
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: isSending ? null : resetForm,
                    icon: const Icon(Icons.restart_alt_sharp),
                  ),
                  ElevatedButton(
                      onPressed: isSending ? null : saveItem,
                      child: isSending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Add Item')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
