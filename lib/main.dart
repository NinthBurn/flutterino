import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:techware_flutter/add_page.dart';
import 'package:techware_flutter/edit_page.dart';
import 'package:techware_flutter/inspect_page.dart';
import 'package:techware_flutter/models/ComputerComponent.dart';
import 'package:techware_flutter/repository/ComputerComponentRepository.dart';

void main() {
  runApp(
      const MyApp()
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xff99cc00),
        systemNavigationBarColor: Color(0xff99cc00),
        systemNavigationBarDividerColor: Color(0xff99cc00),
        statusBarBrightness: Brightness.light,
      )
    );

    return MaterialApp(
        title: 'TechWare Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
          useMaterial3: true,
        ),

        routes: {
          "/add": (context) => AddPage(),
          "/": (context) => HomeWidget(),
        },
    );
  }
}

class HomeWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeWidgetState();
  }
}

class _HomeWidgetState extends State<HomeWidget> {
  final ComputerComponentRepository repository = ComputerComponentRepository();
  late final List<ComputerComponent> products;

  @override
  void initState() {
    super.initState();

    for(int i = 0; i < 20; ++i) {
      repository.add(ComputerComponent(name: "Product ${i+1}", manufacturer: "AMD", category: "Category ${i+1}", price: (i+1) * 99.99, quantity: (i+1)*10, releaseDate: DateTime.now()));
    }

    products = repository.getAll();
  }

  void _navigateToAddScreen() async {
    final addedComponent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPage(),
      ),
    );

    if (addedComponent != null) {
      setState(() {
        repository.add(addedComponent);
        products.add(addedComponent);
      });

      print('Component added: $addedComponent');
    }
  }

  ListView componentListWidget() {
    return ListView.builder(
      addAutomaticKeepAlives: true,
      itemCount: products.length,

      itemBuilder: (context, index) {
        final product = products[index];

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: const Color(0xfff4fff4),
            child: ListTile(
              key: ValueKey(product.id),

              onTap: () {
                print("Tapped on item with index $index");

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InspectPage(component: products[index]),
                  ),
                );
              },

              title: productCardWidget(context, product),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _editButtonWidget(context, index),
                  const SizedBox(width: 10),
                  _deleteButtonWidget(context, index, product.id),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget productCardWidget(BuildContext context, ComputerComponent component) {
    print("building widget for " + component.id.toString());

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(component.category,
            style: const TextStyle(fontSize: 12),
          ),

          Text(component.name,
            style: const TextStyle(fontSize: 14),
          ),

          Text('${component.price.toStringAsFixed(2)}\$, ${component.quantity} ${component.quantity > 1 ? 'units in stock' : 'unit in stock'}',
            style: const TextStyle(fontSize: 12),
          ),
        ]
    );
  }

  Widget _deleteButtonWidget(BuildContext context, int index, int productId) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff99cc00), // White background for the first button
        shape: BoxShape.circle,
      ),

      child: IconButton(
        icon: const Icon(Icons.delete, color: Colors.white),

        onPressed: () {
          _showConfirmDialog(context, "Do you want to delete this item?").then((onValue) => {
            if(onValue == true) {
              repository.remove(productId),

              setState(() {
                products.removeAt(index);
              })
            }
          });
        },

      ),
    );
  }

  Widget _editButtonWidget(BuildContext context, int index) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff99cc00), // White background for the first button
        shape: BoxShape.circle,
      ),

      child: IconButton(
        icon: const Icon(Icons.edit, color: Colors.white),

        onPressed: () async {
          ComputerComponent? component = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPage(component: products[index]),
            ),
          );

          if(component != null) {
            repository.update(component);

            setState(() {
              products[index] = component;
            });
          }
        },

      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );

    Widget continueButton = ElevatedButton(
      child: const Text("Yes"),
      onPressed: () {
        // returnValue = true;
        Navigator.of(context).pop(true);
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Delete item"),
      content: Text(message),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    final result = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffedffe9),

      appBar: AppBar(
        title: const Text('TechWare Manager',
          style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: const Color(0xff99cc00),
      ),

      body: componentListWidget(),

      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        backgroundColor: const Color(0xff99cc00),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

