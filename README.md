# Cheez n' Cream Co. Admin App

A comprehensive Flutter-based admin application for managing orders, products, customers, expenses, and sales analytics for Cheez n' Cream Co.

## 📱 Overview

This admin application provides a complete solution for managing a dessert business, featuring real-time data synchronization, comprehensive reporting, and intuitive user interface. Built with Flutter and Firebase, it offers seamless management of all business operations.

## ✨ Features

### 🔐 Authentication
- **Secure Login**: Email and password authentication using Firebase Auth
- **Remember Me**: Option to save credentials locally for quick access
- **Session Management**: Automatic session handling and logout functionality

### 📊 Dashboard
- **Today's Overview**: Real-time statistics for the current day
  - Total Order Revenue
  - Order Count
  - Total Pieces Sold
  - Net Profit
- **All Time Overview**: Comprehensive statistics across all time
  - Total Revenue
  - Total Pieces Sold
  - Net Profit (Revenue - Expenses)
  - Total Orders Count
- **Swipeable Views**: Easy navigation between Today and All Time views with page indicators
- **Quick Access Grid**: Direct navigation to all major features

### 🛍️ Products Management
- **Product CRUD Operations**:
  - Add new products with name, variant (normal/small), price, and cost
  - Edit existing products
  - Delete products with confirmation
  - View product details
- **Product Variants**: Support for different product sizes (normal, small)
- **Image Management**: 
  - Upload product images from device gallery
  - Local image storage (device-only, not cloud-uploaded)
  - Placeholder images for products without images
- **Product Information**:
  - Product name and description
  - Pricing (selling price and cost)
  - Variant selection
  - Real-time product list updates

### 📦 Orders Management
- **Order Creation**:
  - Customer selection from existing customers or new customer entry
  - Support for single items and combo packs
  - Multiple flavor selection for combo packs (Small and Standard combos)
  - Variant filtering (small/normal) for menu items
  - Pickup date and time scheduling
  - Payment method selection (COD or Pickup)
  - Payment channel (Cash or QR)
  - COD fee calculation and address entry
  - Automatic total calculation
- **Order Viewing**:
  - View orders by date (Today mode) or all orders (All Time mode)
  - Status filtering (All, Pending, Completed)
  - Date picker for historical order viewing
  - Order details with complete information
- **Order Management**:
  - Update order status (Pending/Completed)
  - Edit payment status for incomplete orders (mark as paid/unpaid)
  - Payment confirmation when marking orders as completed
  - Delete orders with confirmation
  - Real-time order updates via Firestore streams
- **Order Details**:
  - Customer information
  - Order items breakdown
  - Combo pack allocations by flavor
  - Payment information (editable for incomplete orders)
  - Pickup date/time (editable)
  - Total pieces and price

### 👥 Customers Management
- **Customer CRUD Operations**:
  - Add new customers with name, phone, and address
  - Edit existing customer information
  - Delete customers with confirmation
- **Customer Search**:
  - Real-time search by name, phone number, or address
  - Filtered customer list display
- **Customer Information Display**:
  - Customer name with avatar
  - Contact number
  - Delivery address
  - Quick access to edit and delete options

### 💰 Expenses Management
- **Expense Tracking**:
  - Add expenses with multiple items
  - Category-based organization (Packaging, Ingredients, Utilities, Commission, Expense, Gas, Storage, etc.)
  - Subcategory support for detailed tracking
  - Supplier management (Sabasun, ECO, Mydin, Shopee, Kedai Plastik Buluh Gading)
  - Date-based expense entry
- **Expense Features**:
  - Multiple items per expense entry
  - Automatic total calculation per item and overall
  - Edit existing expenses
  - Delete expenses with confirmation
- **Expense Views**:
  - Today's expenses view
  - All expenses view
  - Date picker for historical viewing
- **Expense Analytics**:
  - Total expenses summary
  - Category-wise breakdown
  - Top 3 expense categories display
  - Number of categories used

### 📈 Sales Reports
- **Sales Analytics**:
  - Total sales revenue
  - Total orders count
  - Total pieces sold
  - Top selling products (ranked by quantity)
  - Product-wise revenue breakdown
- **View Modes**:
  - Today's sales view
  - All time sales view
  - Date picker for historical sales data
- **PDF Export**:
  - Generate comprehensive sales reports in PDF format
  - Includes summary statistics
  - Top 20 selling products table
  - Date and generation timestamp
  - Share PDF via device sharing options

### 📋 Daily Summary
- **Summary Statistics**:
  - Total orders count
  - Total pieces sold
  - Total revenue
  - Total expenses
  - Net profit calculation (Revenue - Expenses)
- **Flavor Breakdown**:
  - Detailed count of each flavor sold
  - Sorted by popularity
  - Visual representation of flavor distribution
- **View Modes**:
  - Today's summary
  - All time summary
  - Date picker for historical summaries

### 🔍 Order Analysis
- **Payment Method Analysis**:
  - Filter orders by payment method (All, COD, Pickup)
  - COD orders count and revenue
  - Pickup orders count and revenue
  - Side-by-side comparison cards
- **Date-based Analysis**:
  - Select any date to view scheduled pickup/COD orders
  - Shows orders based on pickup/COD date (not order creation date)
  - View orders filtered by payment method
  - Detailed order list with payment information
  - Displays orders that need to be picked up or delivered on the selected date

### 🎁 Combo Pack Support
- **Combo Types**:
  - Small Combo: Tiramisu, Cheesekut, Oreo Cheesekut
  - Standard Combo: Tiramisu, Cheesekut, Oreo Cheesekut, Bahumisu
- **Combo Allocation**:
  - Select quantity for each flavor in combo packs
  - Visual flavor selection interface
  - Automatic calculation of combo pack totals

### 💳 Payment Features
- **Payment Methods**:
  - COD (Cash on Delivery) with fee calculation
  - Pickup payment
- **Payment Channels**:
  - Cash payment
  - QR code payment
- **Payment Status Tracking**:
  - Mark orders as paid/unpaid
  - Edit payment status for incomplete orders directly from order card or detail screen
  - Payment checkbox available for pending orders
  - Payment confirmation when completing orders
  - Real-time payment status updates
- **Scan to Pay**:
  - QR code display for payment
  - Quick access from dashboard

### 🎨 User Interface
- **Modern Design**:
  - Material Design 3 components
  - Custom theme with brand colors
  - Smooth animations and transitions
  - Bounce navigation effects
  - Smooth reveal animations for list items
- **Custom Fonts**:
  - Mirador font family (multiple weights)
  - Outfit font family (multiple weights)
- **SVG Icons**: Custom SVG icons throughout the app
- **Responsive Layout**: Adapts to different screen sizes
- **Empty States**: Helpful empty state messages with action buttons

### 🔄 Real-time Data
- **Firestore Integration**:
  - Real-time data synchronization
  - Automatic UI updates when data changes
  - Stream-based data fetching
  - Efficient data filtering and querying

### 📱 Additional Features
- **Date Formatting**: Smart date display (Today, Yesterday, specific dates)
- **Price Formatting**: Consistent currency formatting (RM)
- **Form Validation**: Comprehensive input validation
- **Error Handling**: User-friendly error messages
- **Toast Notifications**: Success and error feedback
- **Loading States**: Visual feedback during data operations

## 🛠️ Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language

### Backend & Services
- **Firebase Core**: Firebase initialization
- **Firebase Auth**: User authentication
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: File storage (if needed)

### Key Dependencies
- `firebase_core: ^4.2.1` - Firebase core functionality
- `firebase_auth: ^6.1.2` - Authentication
- `cloud_firestore: ^6.1.0` - Database
- `fluttertoast: ^9.0.0` - Toast notifications
- `intl: ^0.19.0` - Internationalization and date formatting
- `shared_preferences: ^2.2.2` - Local storage
- `google_fonts: ^6.1.0` - Google Fonts integration
- `flutter_svg: ^2.0.9` - SVG icon support
- `image_picker: ^1.0.7` - Image selection
- `path_provider: ^2.1.1` - File system paths
- `pdf: ^3.11.1` - PDF generation
- `printing: ^5.13.3` - PDF printing
- `share_plus: ^10.1.2` - File sharing
- `url_launcher: ^6.2.5` - URL launching

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── customer.dart
│   ├── order.dart
│   ├── product.dart
│   ├── expense.dart
│   ├── sale.dart
│   ├── daily_summary.dart
│   └── combo_pack.dart
├── screens/                  # UI screens
│   ├── login.dart
│   ├── dashboard.dart
│   ├── products.dart
│   ├── add_product.dart
│   ├── edit_product.dart
│   ├── product_detail.dart
│   ├── orders.dart
│   ├── add_order.dart
│   ├── order_detail.dart
│   ├── customers.dart
│   ├── add_customer.dart
│   ├── expenses.dart
│   ├── add_expense.dart
│   ├── sales.dart
│   ├── daily_summary.dart
│   └── order_analysis.dart
├── services/                 # Business logic
│   ├── firebase_auth_service.dart
│   ├── firestore_service.dart
│   ├── local_storage_service.dart
│   └── summary_service.dart
├── widgets/                  # Reusable widgets
│   ├── custom_textfield.dart
│   ├── password_field.dart
│   ├── product_card.dart
│   ├── order_card.dart
│   ├── empty_state.dart
│   ├── svg_icon.dart
│   ├── smooth_reveal.dart
│   ├── flavor_count_tile.dart
│   └── combo_flavor_tile.dart
└── utils/                    # Utilities
    ├── app_theme.dart
    ├── price_calculator.dart
    ├── date_formatter.dart
    ├── navigation_helper.dart
    └── constants.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.2.0)
- Dart SDK
- Firebase project setup
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd cheez_admin_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add Android app to Firebase project
   - Download `google-services.json` and place it in `android/app/`
   - Configure Firebase Auth and Firestore
   - Update `firebase_options.dart` with your Firebase configuration

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

1. **Firestore Database**:
   - Create collections: `products`, `orders`, `customers`, `expenses`, `sales`
   - Set up appropriate security rules
   - Create composite index for `pickupDateTime` field in `orders` collection (required for Order Analysis feature)

2. **Firebase Authentication**:
   - Enable Email/Password authentication
   - Create admin user account

3. **Firestore Security Rules**:
   - Configure rules based on your security requirements
   - Ensure authenticated users can read/write data

## 📱 Usage

### Login
1. Enter admin email and password
2. Optionally check "Remember me" to save credentials
3. Tap "Login" to access the dashboard

### Managing Products
1. Navigate to Products from dashboard
2. Tap "+" to add a new product
3. Fill in product details (name, variant, price, cost)
4. Optionally add product image
5. Save the product

### Creating Orders
1. Navigate to Orders from dashboard
2. Tap "+" to create a new order
3. Select or add customer
4. Add items (single items or combo packs)
5. Set pickup date/time
6. Choose payment method and channel
7. Review total and save order

### Tracking Expenses
1. Navigate to Expenses from dashboard
2. Tap "+" to add expense
3. Select category and subcategory
4. Add expense items with quantities and prices
5. Optionally select supplier
6. Save expense

### Viewing Reports
1. Navigate to Sales for sales reports
2. Navigate to Daily Summary for daily analytics
3. Navigate to Order Analysis for payment method analysis
4. Use date picker to view historical data
5. Export sales reports as PDF

## 🎯 Key Workflows

### Order Processing
1. Customer places order → Create order in app
2. Order appears in Orders screen (Pending status)
3. Prepare order → Update order status
4. Mark as completed → Confirm payment
5. Order appears in completed orders

### Expense Tracking
1. Purchase items → Add expense entry
2. Categorize expense → Select category/subcategory
3. Add items → Enter quantities and prices
4. Save expense → Expense appears in summary
5. View in Daily Summary → See impact on profit

### Sales Analysis
1. View Sales screen → See today's sales
2. Switch to All Time → See historical data
3. Export PDF → Generate shareable report
4. Analyze top products → Identify best sellers

## 🔒 Security Features
- Firebase Authentication for secure access
- Firestore security rules for data protection
- Local credential storage (encrypted)
- Input validation on all forms
- Confirmation dialogs for destructive actions

## 📊 Data Models

### Order
- Customer information
- Order items (single items and combo packs)
- Payment details
- Status tracking
- Date and time information

### Product
- Name, variant, price, cost
- Description and image
- Real-time inventory tracking

### Customer
- Name, phone, address
- Order history (linked via orders)

### Expense
- Category and subcategory
- Multiple items
- Supplier information
- Date and total cost

## 🎨 Customization

### Themes
- Modify `lib/utils/app_theme.dart` to change colors and styles
- Customize fonts in `pubspec.yaml`

### Icons
- Replace SVG icons in `assets/icons/`
- Update icon references in code

### Product Images
- Add product images to `assets/images/`
- Or use device gallery for product images

## 🐛 Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Ensure `google-services.json` is in correct location
   - Check Firebase configuration in `firebase_options.dart`

2. **Authentication errors**
   - Verify Firebase Auth is enabled
   - Check email/password format

3. **Data not loading**
   - Check Firestore security rules
   - Verify internet connection
   - Check Firebase console for errors
   - For Order Analysis: Ensure Firestore composite index for `pickupDateTime` is created (Firestore will provide a link if index is missing)

4. **Image picker not working**
   - Grant storage permissions
   - Check device storage availability

## 📝 Notes

- Product images are stored locally on device (not uploaded to cloud)
- Orders with zero items/pieces/price are automatically filtered out
- COD fees are included in order totals
- All prices are in Malaysian Ringgit (RM)
- Date formats follow Malaysian locale

## 🔄 Future Enhancements

Potential features for future versions:
- Inventory management
- Push notifications
- Multi-user support with roles
- Advanced analytics and charts
- Export to Excel
- Backup and restore functionality
- Offline mode support

## 📄 License

[Specify your license here]

## 👥 Contributors

[Add contributors here]

## 📞 Support

For issues and questions, please contact [your contact information]

---

**Built with ❤️ for Cheez n' Cream Co.**

