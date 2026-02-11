// // lib/models/cart_model.dart
// import 'package:flutter/foundation.dart';

// class CartItem {
//   final String title;
//   final String imageUrl;
//   final String price;
//   int quantity;

//   CartItem({
//     required this.title,
//     required this.imageUrl,
//     required this.price,
//     this.quantity = 1,
//   });

//   factory CartItem.fromMap(Map<String, dynamic> map) {
//     return CartItem(
//       title: map['name'] as String,
//       imageUrl: map['image'] as String,
//       price: map['price'].toString(),
//       quantity: map['qty'] as int,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'name': title,
//       'image': imageUrl,
//       'price': double.tryParse(price) ?? 0.0,
//       'qty': quantity,
//     };
//   }
// }

// class CartModel extends ChangeNotifier {
//   final List<CartItem> _items = [];

//   List<CartItem> get items => List.unmodifiable(_items);

//   void addItem(String title, String imageUrl, String price) {
//     int existingIndex = _items.indexWhere((item) => item.title == title);

//     if (existingIndex != -1) {
//       _items[existingIndex].quantity++;
//     } else {
//       _items.add(CartItem(title: title, imageUrl: imageUrl, price: price));
//     }
//     notifyListeners();
//   }

//   void removeItem(CartItem item) {
//     _items.remove(item);
//     notifyListeners();
//   }

//   void updateItemQuantity(CartItem item, int newQuantity) {
//     if (newQuantity <= 0) {
//       removeItem(item);
//     } else {
//       item.quantity = newQuantity;
//       notifyListeners();
//     }
//   }

//   double get totalPrice {
//     double total = 0.0;
//     for (var item in _items) {
//       total += (double.tryParse(item.price) ?? 0.0) * item.quantity;
//     }
//     return total;
//   }

//   void clearCart() {
//     _items.clear();
//     notifyListeners();
//   }
// }