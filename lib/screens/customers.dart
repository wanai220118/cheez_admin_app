import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/customer.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../utils/navigation_helper.dart';
import '../widgets/smooth_reveal.dart';
import 'add_customer.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomersScreen extends StatefulWidget {
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _fs.deleteCustomer(customer.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Customer deleted successfully");
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customers"),
        actions: [
          IconButton(
            icon: SvgIcon(
              assetPath: 'assets/icons/add-icon.svg',
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => NavigationHelper.navigateWithBounce(
              context,
              AddCustomerScreen(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or address...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: _fs.getAllCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('No data'));
                }
                
                var allCustomers = snapshot.data!;
                
                // Filter customers based on search
                final searchQuery = _searchController.text.toLowerCase();
                var customers = allCustomers.where((customer) {
                  if (searchQuery.isEmpty) return true;
                  return customer.name.toLowerCase().contains(searchQuery) ||
                      customer.contactNo.toLowerCase().contains(searchQuery) ||
                      customer.address.toLowerCase().contains(searchQuery);
                }).toList();
                
                if (customers.isEmpty) {
                  return SmoothReveal(
                    child: EmptyState(
                      message: searchQuery.isEmpty
                          ? "No customers found"
                          : "No customers match your search",
                      iconPath: 'assets/icons/orders-icon.svg',
                      actionLabel: "Add Customer",
                      onAction: () => NavigationHelper.navigateWithBounce(
                        context,
                        AddCustomerScreen(),
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return SmoothReveal(
                      delay: Duration(milliseconds: index * 50),
                      child: Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(customer.contactNo),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      customer.address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  NavigationHelper.selectionClick();
                                  NavigationHelper.navigateWithBounce(
                                    context,
                                    AddCustomerScreen(existingCustomer: customer),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  NavigationHelper.selectionClick();
                                  _showDeleteDialog(context, customer);
                                },
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

