
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:techware_flutter/models/ComputerComponent.dart';

class InspectPage extends StatefulWidget {
  final ComputerComponent component;

  const InspectPage({super.key, required this.component});

  @override
  State<StatefulWidget> createState() {
    return _InspectPageState();
  }

}

class _InspectPageState extends State<InspectPage> {
  String? productName, category, manufacturer;
  DateTime? releaseDate;
  double? price;
  int? quantity;
  int? id;

  @override
  void initState() {
    super.initState();

    productName = widget.component.name;
    category = widget.component.category;
    manufacturer = widget.component.manufacturer;
    releaseDate = widget.component.releaseDate;
    price = widget.component.price;
    quantity = widget.component.quantity;
    id = widget.component.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inspecting ${productName!}',
          style: const TextStyle(color: Colors.white),),

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        backgroundColor: const Color(0xff99cc00),
      ),
      body: buildUI(),
    );
  }

  Widget buildUI() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Center(child: inspectForm())
      ],
    );
  }

  StatefulWidget datePickerSetup() {
    return TextFormField(
      readOnly: true,

      initialValue: DateFormat("yyyy-MM-dd").format(releaseDate!),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Release date',
      ),
    );
  }

  Widget inspectForm() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Form(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextFormField(
              initialValue: productName!,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Product name',
                )
            ),

            datePickerSetup(),

            TextFormField(
              initialValue: category!,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Category',
                )
            ),

            TextFormField(
              initialValue: manufacturer!,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Manufacturer',
                )
            ),

            TextFormField(
              initialValue: price!.toStringAsFixed(2),
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Price',
                )
            ),

            TextFormField(
              initialValue: quantity.toString(),
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Quantity',
                )
            ),

            Text("Product ID: $id",
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 18,
              )
            )
          ],
        ),
      ),
    );
  }
}