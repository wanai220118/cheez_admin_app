import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/customer.dart';
import '../widgets/empty_state.dart';
import '../widgets/svg_icon.dart';
import '../utils/navigation_helper.dart';
import '../widgets/smooth_reveal.dart';
import 'add_customer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersScreen extends StatefulWidget {
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name'; // 'name', 'recent'
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red[700]),
            ),
            SizedBox(width: 12),
            Text('Delete Customer'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              _fs.deleteCustomer(customer.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Customer deleted successfully");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCustomerActions(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone, color: Colors.blue[700]),
              ),
              title: Text('Call Customer'),
              subtitle: Text(customer.contactNo),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('tel:${customer.contactNo}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  Fluttertoast.showToast(msg: "Cannot make phone call");
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.message, color: Colors.green[700]),
              ),
              title: Text('Send SMS'),
              subtitle: Text('Send a text message'),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('sms:${customer.contactNo}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  Fluttertoast.showToast(msg: "Cannot send SMS");
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.map, color: Colors.orange[700]),
              ),
              title: Text('View on Map'),
              subtitle: Text('Open in maps app'),
              onTap: () async {
                Navigator.pop(context);
                final query = Uri.encodeComponent(customer.address);
                final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  Fluttertoast.showToast(msg: "Cannot open maps");
                }
              },
            ),
            Divider(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit, color: Colors.purple[700]),
              ),
              title: Text('Edit Customer'),
              onTap: () {
                Navigator.pop(context);
                NavigationHelper.navigateWithBounce(
                  context,
                  AddCustomerScreen(existingCustomer: customer),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete, color: Colors.red[700]),
              ),
              title: Text('Delete Customer', style: TextStyle(color: Colors.red[700])),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, customer);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text("Customers"),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 8),
                    Text('Recently Added'),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: SvgIcon(
                assetPath: 'assets/icons/add-icon.svg',
                size: 22,
                color: Colors.white,
              ),
              onPressed: () => NavigationHelper.navigateWithBounce(
                context,
                AddCustomerScreen(),
              ),
              tooltip: 'Add Customer',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or address...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            
            Divider(height: 1),
            
            Expanded(
              child: StreamBuilder<List<Customer>>(
                stream: _fs.getAllCustomers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(height: 16),
                          Text("Loading customers...", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(child: Text('No data'));
                  }
                  
                  var allCustomers = snapshot.data!;
                  
                  // Sort customers
                  if (_sortBy == 'name') {
                    allCustomers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  } else {
                    allCustomers = allCustomers.reversed.toList(); // Recent first
                  }
                  
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
                        iconPath: 'assets/icons/people-group.svg',
                        actionLabel: "Add Customer",
                        onAction: () => NavigationHelper.navigateWithBounce(
                          context,
                          AddCustomerScreen(),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer count header
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '${customers.length} Customer${customers.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: customers.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            final avatarColor = _getAvatarColor(customer.name);
                            
                            return SmoothReveal(
                              delay: Duration(milliseconds: index * 30),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => _showCustomerActions(context, customer),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                avatarColor,
                                                avatarColor.withOpacity(0.7),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: avatarColor.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              customer.name.isNotEmpty 
                                                  ? customer.name[0].toUpperCase() 
                                                  : '?',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        SizedBox(width: 16),
                                        
                                        // Customer Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    customer.contactNo,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                                  SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      customer.address,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[700],
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Quick Actions
                                        Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.phone, color: Colors.blue[700], size: 20),
                                                onPressed: () async {
                                                  NavigationHelper.selectionClick();
                                                  final uri = Uri.parse('tel:${customer.contactNo}');
                                                  if (await canLaunchUrl(uri)) {
                                                    await launchUrl(uri);
                                                  } else {
                                                    Fluttertoast.showToast(msg: "Cannot make phone call");
                                                  }
                                                },
                                                tooltip: 'Call',
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.purple[50],
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.edit, color: Colors.purple[700], size: 20),
                                                onPressed: () {
                                                  NavigationHelper.selectionClick();
                                                  NavigationHelper.navigateWithBounce(
                                                    context,
                                                    AddCustomerScreen(existingCustomer: customer),
                                                  );
                                                },
                                                tooltip: 'Edit',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}