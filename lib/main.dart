import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openDatabase(
    path.join(await getDatabasesPath(), 'crud_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL)',
      );
    },
    version: 1,
  );

  runApp(CRUDApp(database));
}

class CRUDApp extends StatelessWidget {
  final Database database;

  CRUDApp(this.database);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CRUDHomePage(title: 'CRUD Example', database: database),
    );
  }
}

class CRUDHomePage extends StatefulWidget {
  final Database database;

  CRUDHomePage({Key? key, required this.title, required this.database})
      : super(key: key);

  final String title;

  @override
  _CRUDHomePageState createState() => _CRUDHomePageState();
}

class _CRUDHomePageState extends State<CRUDHomePage> {
  late Future<List<Map<String, dynamic>>> _items = Future.value([]);

  @override
  void initState() {
    super.initState();
    refreshItems();
  }

  Future<void> refreshItems() async {
    final db = await widget.database;
    setState(() {
      _items = db.query('items');
    });
  }

  Future<void> addItem(String name, double price) async {
    final db = await widget.database;
    await db.insert('items', {'name': name, 'price': price});
    refreshItems();
  }

  Future<void> updateItem(int id, String name, double price) async {
    final db = await widget.database;
    await db.update(
      'items',
      {'name': name, 'price': price},
      where: 'id = ?',
      whereArgs: [id],
    );
    refreshItems();
  }

  Future<void> deleteItem(int id) async {
    final db = await widget.database;
    await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    refreshItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('Price: \$${item['price']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteItem(item['id']),
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      String itemName = item['name'];
                      double itemPrice = item['price'];
                      return AlertDialog(
                        title: Text('Edit Item'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              decoration: InputDecoration(labelText: 'Name'),
                              onChanged: (value) => itemName = value,
                              controller: TextEditingController(text: itemName),
                            ),
                            TextField(
                              decoration: InputDecoration(labelText: 'Price'),
                              onChanged: (value) =>
                                  itemPrice = double.parse(value),
                              controller: TextEditingController(
                                  text: itemPrice.toString()),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('Save'),
                            onPressed: () {
                              updateItem(item['id'], itemName, itemPrice);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) {
            String? itemName;
            double? itemPrice;
            return AlertDialog(
              title: Text('Add Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    onChanged: (value) => itemName = value,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Price'),
                    onChanged: (value) => itemPrice = double.parse(value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Add'),
                  onPressed: () {
                    if (itemName != null && itemPrice != null) {
                      addItem(itemName!, itemPrice!);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
