import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/product.dart';
import '../models/order.dart' as app_models;
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/customer.dart';

class FirestoreService {
  FirebaseFirestore get _db {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase has not been initialized. Call Firebase.initializeApp() first.');
    }
    return FirebaseFirestore.instance;
  }

  // Products
  Stream<List<Product>> getProducts({bool activeOnly = false}) {
    if (activeOnly) {
      return _db.collection('products')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
    } else {
      return _db.collection('products').snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
    }
  }

  Stream<Product?> getProductById(String id) {
    return _db.collection('products').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _db.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // Delete all products by variant (series)
  Future<void> deleteProductsByVariant(String variant) async {
    final snapshot = await _db.collection('products')
        .where('variant', isEqualTo: variant)
        .get();
    
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Add multiple products in batch
  Future<void> addProductsBatch(List<Product> products) async {
    final batch = _db.batch();
    for (var product in products) {
      final docRef = _db.collection('products').doc();
      batch.set(docRef, product.toMap());
    }
    await batch.commit();
  }

  // Orders
  Stream<List<app_models.Order>> getOrdersByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    return _db.collection('orders')
        .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('orderDate', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          // Filter out any documents that don't exist or have errors
          return snapshot.docs
              .where((doc) => doc.exists)
              .map((doc) {
                try {
                  final data = doc.data();
                  if (data == null || data.isEmpty) return null;
                  return app_models.Order.fromMap(doc.id, data as Map<String, dynamic>);
                } catch (e) {
                  // Skip documents that can't be parsed
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<app_models.Order>()
              .toList();
        });
  }

  Stream<List<app_models.Order>> getAllOrders() {
    return _db.collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          // Filter out any documents that don't exist or have errors
          return snapshot.docs
              .where((doc) => doc.exists)
              .map((doc) {
                try {
                  final data = doc.data();
                  if (data == null || data.isEmpty) return null;
                  return app_models.Order.fromMap(doc.id, data as Map<String, dynamic>);
                } catch (e) {
                  // Skip documents that can't be parsed
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<app_models.Order>()
              .toList();
        });
  }

  Stream<List<app_models.Order>> getOrdersByPickupDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    return _db.collection('orders')
        .where('pickupDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('pickupDateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          // Filter out any documents that don't exist or have errors
          return snapshot.docs
              .where((doc) => doc.exists)
              .map((doc) {
                try {
                  final data = doc.data();
                  if (data == null || data.isEmpty) return null;
                  return app_models.Order.fromMap(doc.id, data as Map<String, dynamic>);
                } catch (e) {
                  // Skip documents that can't be parsed
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<app_models.Order>()
              .toList();
        });
  }

  Future<void> addOrder(app_models.Order order) async {
    await _db.collection('orders').add(order.toMap());
  }

  Future<void> updateOrder(app_models.Order order) async {
    await _db.collection('orders').doc(order.id).update(order.toMap());
  }

  Future<void> deleteOrder(String id) async {
    await _db.collection('orders').doc(id).delete();
  }

  // Sales
  Stream<List<Sale>> getSalesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    return _db.collection('sales')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Sale.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addSale(Sale sale) async {
    await _db.collection('sales').add(sale.toMap());
  }

  // Expenses
  Stream<List<Expense>> getExpensesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    return _db.collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Stream<List<Expense>> getAllExpenses() {
    return _db.collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addExpense(Expense expense) async {
    await _db.collection('expenses').add(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.collection('expenses').doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _db.collection('expenses').doc(id).delete();
  }

  // Customers
  Stream<List<Customer>> getAllCustomers() {
    return _db.collection('customers')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Customer.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addCustomer(Customer customer) async {
    await _db.collection('customers').add(customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.collection('customers').doc(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await _db.collection('customers').doc(id).delete();
  }
}
