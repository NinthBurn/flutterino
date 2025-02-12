import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:techware_flutter/add_page.dart';
import 'package:techware_flutter/edit_page.dart';
import 'package:techware_flutter/inspect_page.dart';
import 'package:techware_flutter/models/ComputerComponent.dart';
import 'package:techware_flutter/services/database_service.dart';
import 'package:techware_flutter/services/api_service.dart';

var logger = Logger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xff99cc00),
      systemNavigationBarColor: Color(0xff99cc00),
      systemNavigationBarDividerColor: Color(0xff99cc00),
      statusBarBrightness: Brightness.light,
    ));

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
  const HomeWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeWidgetState();
  }
}

class _HomeWidgetState extends State<HomeWidget> {
  ApiService apiService = ApiService();
  late List<ComputerComponent> products;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getDataFromAPI();

    apiService.socketStream.listen((event) {
      final changeType = event['type'];
      final componentData = event['data'];
      setState(() {
        if (changeType == 'add') {
          final component = ComputerComponent.fromJson(componentData);
          products.add(component);

        } else if (changeType == 'update') {
          final component = ComputerComponent.fromJson(componentData);
          int index = products.indexWhere((oldComponent) => oldComponent.id == component.id);
          if (index != -1) {
            products[index] = component;
          }

        } else if (changeType == 'delete') {
          int id = componentData['product_id'] as int;

          products.removeWhere((oldComponent) => oldComponent.id == id);

        }
      });
    });
  }

  void _getDataFromAPI() async {
    try {
      List<ComputerComponent> components;
      apiService.connectWebSocket().then((value) async => {
        components = await apiService.getAllComponents(),
        setState(() {
          products = components;
          isLoading = false;
        })
      });

    } catch (error) {
        logger.e("Error while fetching all the components: $error");
        Fluttertoast.showToast(
            msg: "An error occurred while fetching the data",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
    }
  }

  void _navigateToAddScreen() async {
    final addedComponent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPage(),
      ),
    );

    if (addedComponent != null) {
      try {
        var addedId = await apiService.addComponent(addedComponent);
        addedComponent.id = addedId;

        if(addedId <= 0) {
          setState(() {
            products.add(addedComponent);
          });

          Fluttertoast.showToast(
              msg: "No connection to server; operation was performed locally",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0
          );
        }
      } catch (error) {
        logger.e("Error while adding the component: $error");
        Fluttertoast.showToast(
            msg: "An error occurred while adding the component",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
      }
    }
  }

  Widget componentListWidget() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
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
                debugPrint("Tapped on item with index $index");

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          component.category,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          component.name,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          '${component.price.toStringAsFixed(2)}\$, ${component.quantity} ${component.quantity > 1 ? 'units in stock' : 'unit in stock'}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _deleteButtonWidget(BuildContext context, int index, int productId) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff99cc00),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.delete, color: Colors.white),
        onPressed: () {
          _showConfirmDialog(context, "Do you want to delete this item?").then((onValue) => {
            if (onValue == true)
              {
                apiService
                    .deleteComponent(productId)
                    .then((value) => {
                    if(value <= 0)
                      Fluttertoast.showToast(
                          msg: "No connection to server; operation was performed locally",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0
                      ),
                    setState(() {
                      products.removeAt(index);
                    })
                })
                    .catchError((error) => {
                  logger.e("An error occurred while deleting the component: $error"),
                  Fluttertoast.showToast(
                    msg: "An error occurred while deleting the component",
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0
                  ),
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
        color: Color(0xff99cc00),
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

          if (component != null) {
            try {
              apiService.updateComponent(component).then((value) => {
                if(value <= 0)
                  Fluttertoast.showToast(
                      msg: "No connection to server; operation was performed locally",
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0
                  ),
                  setState(() {
                    products[index] = component;
                  })
              });

            } catch (error) {
                logger.e("Error while updating the component: $error");
                Fluttertoast.showToast(
                    msg: "An error occurred while updating the component",
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0
                );
            }
          }
        },
      ),
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    Widget cancelButton = ElevatedButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );

    Widget continueButton = ElevatedButton(
      child: const Text("Yes"),
      onPressed: () {
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

  Future<bool> _showErrorDialog(BuildContext context, String message) async {
    Widget continueButton = ElevatedButton(
      child: const Text("Ok :("),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Application error"),
      content: Text(message),
      actions: [
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
        title: const Text(
          'TechWare Manager',
          style: TextStyle(color: Colors.white),
        ),
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

