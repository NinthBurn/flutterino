
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:techware_flutter/models/ComputerComponent.dart';

class EditPage extends StatefulWidget {
  final ComputerComponent component;

  const EditPage({super.key, required this.component});

  @override
  State<StatefulWidget> createState() {
    return _EditPageState();
  }

}

class _EditPageState extends State<EditPage> {
  final GlobalKey<FormState> _editFormKey = GlobalKey();
  final TextEditingController _date = TextEditingController();

  String? productName, category, manufacturer;
  DateTime? releaseDate = DateTime.now();
  double? price;
  int? quantity;

  @override
  void initState() {
    super.initState();

    productName = this.widget.component.name;
    category = this.widget.component.category;
    manufacturer = this.widget.component.manufacturer;
    releaseDate = this.widget.component.releaseDate;
    price = this.widget.component.price;
    quantity = this.widget.component.quantity;
    _date.text = DateFormat("yyyy-MM-dd").format(releaseDate!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editing ${productName!}',
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
        Center(child: addForm())
      ],
    );
  }

  Widget editButtonSetup() {
    return ElevatedButton(
        onPressed: () {
          if(_editFormKey.currentState?.validate() ?? false) {
            _editFormKey.currentState?.save();
            ComputerComponent addedComponent = ComputerComponent(name: productName!, manufacturer: manufacturer!, category: category!, price: price!, quantity: quantity!, releaseDate: releaseDate!);
            addedComponent.id = widget.component.id;

            Navigator.pop(context, addedComponent);
          }
        },

        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff99cc00)
        ),

        child: const Text("Modify",
          style: TextStyle(
              color: Colors.white
          ),
        )
    );
  }

  StatefulWidget datePickerSetup() {
    return TextFormField(
      validator: (value) {
        if(value == null || value.isEmpty) {
          return "Invalid date";
        }
        return null;
      },

      onSaved: (value) {
        setState(() {
          releaseDate = DateTime.parse(value!);
        });
      },

      controller: _date,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Release date',
      ),

      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: releaseDate == null ? DateTime.now() : releaseDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2101)
        );

        if(pickedDate != null) {
          setState(() {
            // fuck you
            // _date.text = "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
            _date.text = DateFormat("yyyy-MM-dd").format(pickedDate);
          });
        }
      },
    );
  }

  StatefulWidget priceInputSetup() {
    return TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        initialValue: price.toString(),
        validator: (value) {
          if(value == null || value.isEmpty) {
            return "Invalid price; only positive numbers are accepted";
          }
          return null;
        },
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]+\.?[0-9]*')),
        ],

        onSaved: (value) {
          setState(() {
            price = double.parse(value!);
          });
        },

        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Price',
        )
    );
  }

  StatefulWidget quantityInputSetup() {
    return TextFormField(
        keyboardType: TextInputType.number,
        initialValue: quantity.toString(),
        validator: (value) {
          if(value == null || value.isEmpty) {
            return "Invalid quantity; only positive integers are accepted";
          }
          return null;
        },
        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],

        onSaved: (value) {
          setState(() {
            quantity = int.parse(value!);
          });
        },

        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Quantity',
        )
    );
  }

  Widget addForm() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Form(
        key: _editFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextFormField(
              keyboardType: TextInputType.text,
              initialValue: productName,
              validator: (value) {
                if(value == null || value.isEmpty) {
                  return "Invalid product name";
                }
                return null;
              },

              onSaved: (value) {
                setState(() {
                  productName = value;
                });
              },

              decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Product name',
              )
            ),

            datePickerSetup(),

            TextFormField(
                keyboardType: TextInputType.text,
                initialValue: category,
                validator: (value) {
                  if(value == null || value.isEmpty) {
                    return "Invalid product category";
                  }
                  return null;
                },

                onSaved: (value) {
                  setState(() {
                    category = value;
                  });
                },

                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Category',
                )
            ),

            TextFormField(
                keyboardType: TextInputType.text,
                initialValue: manufacturer,
                validator: (value) {
                  if(value == null || value.isEmpty) {
                    return "Invalid manufacturer name";
                  }
                  return null;
                },

                onSaved: (value) {
                  setState(() {
                    manufacturer = value;
                  });
                },

                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Manufacturer',
                )
            ),

            priceInputSetup(),
            quantityInputSetup(),
            editButtonSetup()
          ],
        ),
      ),
    );
  }
}