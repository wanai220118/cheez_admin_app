import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/sale.dart';
import '../models/product.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddSaleScreen extends StatefulWidget {
  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final FirestoreService _fs = FirestoreService();
  List<Product> products = [];
  Product? selectedProduct;
  int quantity = 1;

  @override
  void initState(){
    super.initState();
    _fs.getProducts(activeOnly: true).listen((list){
      setState(() {
        products = list;
        if(products.isNotEmpty) selectedProduct = products[0];
      });
    });
  }

  void saveSale(){
    if(selectedProduct==null) return;
    final sale = Sale(
      id: "",
      productName: selectedProduct!.name,
      variant: selectedProduct!.variant,
      quantity: quantity,
      totalPrice: selectedProduct!.price * quantity,
      date: DateTime.now(),
    );
    _fs.addSale(sale);
    Fluttertoast.showToast(msg: "Sale saved");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("Add Sale")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children:[
            DropdownButton<Product>(
              value: selectedProduct,
              items: products.map((p)=>DropdownMenuItem(value:p, child: Text("${p.name} (${p.variant})"))).toList(),
              onChanged: (v)=>setState(()=>selectedProduct=v),
            ),
            SizedBox(height:20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Quantity: $quantity"),
                Row(
                  children: [
                    IconButton(icon: Icon(Icons.remove), onPressed: (){
                      if(quantity>1) setState(()=>quantity--);
                    }),
                    IconButton(icon: Icon(Icons.add), onPressed: ()=>setState(()=>quantity++)),
                  ],
                )
              ],
            ),
            SizedBox(height:20),
            ElevatedButton(onPressed: saveSale, child: Text("Save Sale")),
          ],
        ),
      ),
    );
  }
}
