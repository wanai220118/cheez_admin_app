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
- **Weekly Overview**: Statistics for the current week (Monday to Sunday)
  - Total Revenue for the week
  - Total Orders Count for the week
  - Average Revenue per Day
  - Total Pieces Sold for the week
  - Daily breakdown showing revenue, pieces, and orders for each day of the week
- **All Time Overview**: Comprehensive statistics across all time
  - Total Revenue
  - Total Pieces Sold
  - Net Profit (Revenue - Expenses)
  - Total Orders Count
- **Swipeable Views**: Easy navigation between Today, Weekly, and All Time views with page indicators
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
  - Support for single items with automatic combo pricing (6 small items = RM10, 3 standard items = RM10)
  - Variant filtering (small/normal) for menu items
  - Pickup date and time scheduling (required field, no asterisk shown but still required)
  - Phone number field (no "optional" label)
  - Payment method selection (COD or Pickup)
  - Payment channel (Cash or QR)
  - COD fee calculation and address entry (COD fee can be set to 0)
  - Automatic total calculation with combo pricing
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
  - **Edit Order Items**: Edit button to modify items in submitted orders
  - Payment information (editable for incomplete orders)
  - Pickup date/time (editable)
  - Total pieces and price
- **Receipt Generation**:
  - Automatic receipt generation when saving orders
  - Beautiful receipt design matching app theme
  - Company logo display (logoresit.png)
  - Receipt preview before sending
  - Download receipt to device gallery
  - WhatsApp integration for sending receipts to customers
  - Auto-opens WhatsApp chat with customer's phone number
  - Receipt includes:
    - Company logo and name
    - Order details (customer, date, time)
    - Pickup schedule
    - Order items list (simple text format)
    - Total pieces and pricing
    - COD fee (if applicable)
    - Payment information
    - Thank you message

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
  - **Custom Item Entry**: "etc." option available in all subcategory dropdowns for custom item names
  - Supplier management (Sabasun, ECO, Mydin, Shopee, Kedai Plastik Buluh Gading)
  - Date-based expense entry
- **Expense Features**:
  - Multiple items per expense entry
  - Automatic total calculation per item and overall
  - Edit existing expenses
  - Delete expenses with confirmation
  - **Flexible Item Entry**: Select from predefined subcategories or enter custom item names
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
- **PDF Export with Filters**:
  - Generate comprehensive sales reports in PDF format
  - **Date Filtering Options**:
    - Export current date data
    - Export date range (select start and end dates)
    - Export all time data
  - **Content Filtering**:
    - Include/exclude summary statistics
    - Include/exclude top products table
  - Includes summary statistics (when enabled)
  - Top 20 selling products table (when enabled)
  - Date range and generation timestamp
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
  - COD orders count and revenue (shown only when "All" is selected)
  - Pickup orders count and revenue (shown only when "All" is selected)
  - Side-by-side comparison cards (hidden when COD or Pickup tab is selected)
  - Flavor breakdown by series and size (shown only when "All" is selected)
- **Flavor Breakdown Table**:
  - Organized by Series (Tiramisu, Cheesekut, etc.)
  - Grouped by Size (Small, Big, Combo)
  - Each flavor displayed on its own row
  - Table format with 4 columns: Series | Size | Flavor | Quantity
  - Easy to scan and analyze product sales by category
  - Includes all purchased items (single items and combo packs)
- **Date-based Analysis**:
  - Select any date to view scheduled pickup/COD orders
  - Shows orders based on pickup/COD date (not order creation date)
  - View orders filtered by payment method
  - Detailed order list with payment information
  - Displays orders that need to be picked up or delivered on the selected date
- **PDF Export with Filters**:
  - Export order analysis reports in PDF format
  - **Content Filtering Options**:
    - Include/exclude summary statistics
    - Include/exclude flavor breakdown table (with series and size grouping)
    - Include/exclude orders list
  - **Date Filtering Options**:
    - Export current date data
    - Export date range (select start and end dates)
    - Export single date data
  - Flavor breakdown table matches on-screen display format
  - Date range and generation timestamp
  - Share PDF via device sharing options

### 🎁 Combo Pack Support
- **Automatic Combo Pricing**:
  - 7 small items automatically priced as RM10 combo
  - Combo pricing applied automatically when quantities meet requirements
  - Remaining items priced individually
- **Combo Calculation**:
  - Automatic detection of combo-eligible quantities
  - Smart pricing calculation for mixed orders
  - No separate combo section needed - handled automatically

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
- `path: ^1.8.3` - Path manipulation utilities
- `pdf: ^3.11.1` - PDF generation
- `printing: ^5.13.3` - PDF printing
- `share_plus: ^10.1.2` - File sharing
- `url_launcher: ^6.2.5` - URL launching
- `flutter_dotenv: ^5.1.0` - Environment variables management
- `screenshot: ^3.0.0` - Widget to image conversion for receipts
- `cross_file: ^0.3.4` - Cross-platform file handling
- `webview_flutter: ^4.4.2` - WebView support (for receipt viewing)

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
│   ├── add_sale.dart
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
│   ├── combo_flavor_tile.dart
│   └── receipt_widget.dart  # Receipt display widget
├── screens/                  # UI screens
│   ├── receipt_viewer.dart  # Receipt HTML viewer
│   └── ...
└── utils/                    # Utilities
    ├── app_theme.dart
    ├── price_calculator.dart
    ├── date_formatter.dart
    ├── navigation_helper.dart
    ├── constants.dart
    ├── receipt_image_generator.dart  # Receipt image generation
    └── html_receipt_generator.dart   # HTML receipt template
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
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/google-services.json` (this file is gitignored for security)
   - Configure Firebase Auth and Firestore
   - **Important**: Never commit `google-services.json` to version control as it contains sensitive API keys

4. **Environment Variables Setup**
   - Create a `.env` file in the root directory of the project
   - Add your Firebase API keys and configuration:
     ```
     GOOGLE_API_KEY=your_google_api_key_here
     FIREBASE_APP_ID=your_firebase_app_id_here
     FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id_here
     FIREBASE_PROJECT_ID=your_project_id_here
     FIREBASE_DATABASE_URL=your_database_url_here
     FIREBASE_STORAGE_BUCKET=your_storage_bucket_here
     ```
   - The `.env` file is already added to `.gitignore` to keep your keys secure
   - You can find these values in your Firebase console or `google-services.json` file
   - **Security Note**: The app uses `flutter_dotenv` to load environment variables. While the app will continue without `.env` in development, it's recommended to have it for production use

5. **Run the app**
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
5. Set pickup date/time (required)
6. Choose payment method and channel
7. Enter COD fee if applicable (can be 0)
8. Review total and save order
9. Receipt preview will appear automatically
10. Download receipt to gallery and send via WhatsApp

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

### Adding Sales
1. Navigate to Sales from dashboard
2. Tap "+" to add a new sale entry
3. Select product from dropdown
4. Enter quantity
5. Save sale (automatically calculates total price)

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
- Environment variables for API keys (`.env` file)
- Sensitive files excluded from version control (`.gitignore`)

### ⚠️ Security Best Practices
- **Never commit API keys**: The `.env` file and `google-services.json` are in `.gitignore`
- **Rotate keys if leaked**: If your API keys are exposed, immediately:
  1. Go to Google Cloud Console → APIs & Services → Credentials
  2. Delete or restrict the exposed API key
  3. Create a new API key with proper restrictions
  4. Update your `.env` file with the new key
  5. Update `google-services.json` from Firebase Console
- **Use API key restrictions**: In Google Cloud Console, restrict your API keys to specific:
  - Android apps (package name + SHA-1)
  - APIs (only Firebase services needed)
  - IP addresses (if applicable)

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
- COD fees are included in order totals (COD fee can be set to 0)
- All prices are in Malaysian Ringgit (RM)
- Date formats follow Malaysian locale
- The app uses environment variables from `.env` file for Firebase configuration
- `google-services.json` should be placed in `android/app/` directory (gitignored for security)
- Receipt images are saved to device gallery (Pictures/CheezReceipts folder on Android)
- WhatsApp integration requires WhatsApp to be installed on the device
- Receipt logo file (`logoresit.png`) should be placed in `assets/images/` directory
- Pickup date/time is required when creating orders

## 📄 Receipt Features

### Receipt Generation
- **Automatic Generation**: Receipts are automatically generated when orders are saved
- **Beautiful Design**: Receipt matches app theme with brand colors (dark brown, golden brown, tan)
- **Company Branding**: Includes company logo (`logoresit.png`) and name in header
- **Complete Information**: Shows all order details including:
  - Customer information
  - Order date and time
  - Pickup schedule
  - Order items (simple text format: "Item Name (variant): quantity pcs")
  - Total pieces
  - Order price
  - COD fee (if applicable)
  - Payment information
  - Thank you message

### Receipt Sharing
- **Preview Before Sending**: View receipt image before sharing
- **Download to Gallery**: Save receipt image to device gallery
- **WhatsApp Integration**: 
  - Automatically opens WhatsApp chat with customer's phone number
  - Receipt is saved to gallery for easy attachment
  - Streamlined workflow for sending receipts to customers
- **Image Format**: Receipts are generated as PNG images (high quality, 2x pixel ratio)

### Receipt Styling
- **Compact Design**: Optimized spacing to prevent overflow
- **Responsive Layout**: Adapts to content length
- **Professional Appearance**: Clean, modern design suitable for business use
- **Brand Consistency**: Uses app theme colors throughout

## 🔄 Future Enhancements

Potential features for future versions:
- Inventory management
- Push notifications
- Multi-user support with roles
- Advanced analytics and charts
- Export to Excel
- Backup and restore functionality
- Offline mode support
- Receipt templates customization
- Email receipt sending

---

**Built with ❤️ for Cheez n' Cream Co.**

