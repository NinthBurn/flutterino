
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

    productName = widget.component.name;
    category = widget.component.category;
    manufacturer = widget.component.manufacturer;
    releaseDate = widget.component.releaseDate;
    price = widget.component.price;
    quantity = widget.component.quantity;
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
        Center(child: editForm())
      ],
    );
  }

  Widget editButtonSetup() {
    return ElevatedButton(
        onPressed: () {
          if(_editFormKey.currentState?.validate() ?? false) {
            _editFormKey.currentState?.save();
            ComputerComponent selectedComponent = ComputerComponent(name: productName!, manufacturer: manufacturer!, category: category!, price: price!, quantity: quantity!, releaseDate: releaseDate!);
            selectedComponent.id = widget.component.id;

            Navigator.pop(context, selectedComponent);
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
            initialDate: releaseDate ?? DateTime.now(),
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

  StatefulWidget productNameInputSetup() {
    return TextFormField(
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
    );
  }

  StatefulWidget categoryInputSetup() {
    return TextFormField(
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
    );
  }

  StatefulWidget manufacturerInputSetup() {
    return TextFormField(
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
    );
  }

  Widget editForm() {
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
            productNameInputSetup(),
            datePickerSetup(),
            categoryInputSetup(),
            manufacturerInputSetup(),
            priceInputSetup(),
            quantityInputSetup(),
            editButtonSetup()
          ],
        ),
      ),
    );
  }
}