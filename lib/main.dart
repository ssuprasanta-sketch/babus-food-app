import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'session.dart';
import 'login_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';
import 'product_detail_page.dart';

void main() {
  runApp(const BabusFoodApp());
}

/// Decides whether to show Login or go straight to the Home page,
/// based on whether the user is already logged in on this device.
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool checking = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await Session.load();
    setState(() {
      loggedIn = user != null;
      checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF8F3),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
          ),
        ),
      );
    }
    return loggedIn ? const HomePage() : const LoginPage();
  }
}

class BabusFoodApp extends StatelessWidget {
  const BabusFoodApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Babu\'s Food',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF8F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF6B35),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;
  Map<String, dynamic>? currentUser;

  // Food image URLs (using placeholder food images)
  final Map<String, String> foodImages = {
    'Chicken Thali': 'https://images.unsplash.com/photo-1596195594529-3a7e3be3fcde?w=400&h=400&fit=crop',
    'Veg Thali': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=400&fit=crop',
    'Dal Roti': 'https://images.unsplash.com/photo-1603040942614-b4fb8d504427?w=400&h=400&fit=crop',
  };

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _loadUser();
    // Quietly re-check for product changes (new images, prices, availability)
    // every 15 seconds while the home screen is open, so admin updates show
    // up without the customer needing to close and reopen the app.
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchProducts(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await Session.load();
    setState(() => currentUser = user);
  }

  Future<void> _logout() async {
    await Session.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> fetchProducts({bool silent = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$kApiBaseUrl/products'),
      );

      if (response.statusCode == 200) {
        final fetched = List<Map<String, dynamic>>.from(
          json.decode(response.body)['products'],
        );
        if (!mounted) return;
        // Avoid unnecessary rebuilds/flicker if nothing actually changed
        if (silent && json.encode(fetched) == json.encode(products)) return;
        setState(() {
          products = fetched;
          isLoading = false;
        });
      }
    } catch (e) {
      if (silent) return; // don't replace good data with fallback on a background hiccup
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
        // Default products with descriptions
        products = [
          {
            'id': 1,
            'name': 'Chicken Thali',
            'price': 200,
            'description': 'Aromatic basmati rice, creamy dal, tender chicken curry, fresh seasonal vegetables',
            'image_url': foodImages['Chicken Thali'],
            'category': 'non-veg',
          },
          {
            'id': 2,
            'name': 'Veg Thali',
            'price': 120,
            'description': 'Fluffy rice, silky dal, assorted vegetables, warm traditional roti',
            'image_url': foodImages['Veg Thali'],
            'category': 'veg',
          },
          {
            'id': 3,
            'name': 'Dal Roti',
            'price': 90,
            'description': 'Creamy lentil curry with ghee, freshly made butter roti',
            'image_url': foodImages['Dal Roti'],
            'category': 'meals',
          },
        ];
      });
    }
  }

  void addToCart(Map<String, dynamic> product) {
    setState(() {
      var existingItem = cart.firstWhere(
        (item) => item['id'] == product['id'],
        orElse: () => {},
      );

      if (existingItem.isNotEmpty) {
        existingItem['quantity']++;
      } else {
        cart.add({...product, 'quantity': 1});
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🍛 Babu\'s Food',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, size: 28),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(cart: cart, currentUser: currentUser),
                  ),
                ),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 24),
            tooltip: 'My Orders',
            onPressed: currentUser == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersPage(userId: currentUser!['id']),
                      ),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 24),
            tooltip: 'My Profile',
            onPressed: currentUser == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(currentUser: currentUser!),
                      ),
                    ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchProducts,
              color: const Color(0xFFFF6B35),
              child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                // Header Section
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser != null
                            ? 'Hungry, ${currentUser!['name'].toString().split(' ').first}? 😋'
                            : 'Hungry? Let\'s fix that 😋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fresh, homemade recipes delivered hot to your door',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Products grouped by category
                ..._buildCategorySections(),
              ],
              ),
            ),
    );
  }

  List<Widget> _buildCategorySections() {
    if (products.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No dishes added yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Add products from the admin dashboard',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
          ),
        ),
      ];
    }

    const categoryOrder = ['veg', 'non-veg', 'meals', 'drinks'];
    const categoryLabels = {
      'veg': '🥦 Veg',
      'non-veg': '🍗 Non-Veg',
      'meals': '🍱 Meals',
      'drinks': '🥤 Drinks',
    };

    final widgets = <Widget>[];

    for (final cat in categoryOrder) {
      final items = products.where((p) => (p['category'] ?? 'veg') == cat).toList();
      if (items.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Text(
            categoryLabels[cat] ?? cat,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ),
      );

      widgets.add(
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, i) => _buildThumbnailCard(items[i]),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 20));
    }

    return widgets;
  }

  Widget _buildThumbnailCard(Map<String, dynamic> product) {
    final hasImage = product['image_url'] != null && product['image_url'].toString().isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: product,
              onAddToCart: addToCart,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 110,
                width: double.infinity,
                color: Colors.grey[200],
                child: hasImage
                    ? Image.network(
                        product['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.restaurant, size: 36, color: Colors.grey[400]),
                      )
                    : Icon(Icons.restaurant, size: 36, color: Colors.grey[400]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product['price']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOldProductCard(Map<String, dynamic> product) {
    return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Food Image
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              image: (product['image_url'] != null && product['image_url'].toString().isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(product['image_url']),
                                      fit: BoxFit.cover,
                                      onError: (_, __) {},
                                    )
                                  : null,
                            ),
                            child: (product['image_url'] == null || product['image_url'].toString().isEmpty)
                                ? Center(
                                    child: Icon(
                                      Icons.restaurant,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                  )
                                : null,
                          ),
                          // Product Details
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['name'],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C2C2C),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '₹${product['price']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product['description'] ?? 'Delicious food',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => addToCart(product),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B35),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add to Cart',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
  }
}

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Map<String, dynamic>? currentUser;

  const CartPage({Key? key, required this.cart, this.currentUser}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    double total = widget.cart.fold(
      0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: widget.cart.isEmpty
          ? const Center(
              child: Text('Your cart is empty'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      var item = widget.cart[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${item['price']} × ${item['quantity']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${item['price'] * item['quantity']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Remove',
                                onPressed: () {
                                  setState(() {
                                    widget.cart.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹$total',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    total: total,
                                    cart: widget.cart,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Proceed to Checkout',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final double total;
  final List<Map<String, dynamic>> cart;
  final Map<String, dynamic>? currentUser;

  const CheckoutPage({
    Key? key,
    required this.total,
    required this.cart,
    this.currentUser,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final nameController = TextEditingController(text: widget.currentUser?['name'] ?? '');
  late final phoneController = TextEditingController(text: widget.currentUser?['phone'] ?? '');
  final houseController = TextEditingController();
  final areaController = TextEditingController();
  final couponController = TextEditingController();
  bool isProcessing = false;
  bool isLocating = false;
  double? latitude;
  double? longitude;
  double discountPercent = 0;
  String? appliedCoupon;
  bool isApplyingCoupon = false;
  String? couponMessage;

  double get discountAmount => widget.total * (discountPercent / 100);
  double get finalTotal => widget.total - discountAmount;

  Future<void> _useCurrentLocation() async {
    setState(() => isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please turn on Location in your phone settings');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Enable it from phone Settings.');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📍 Location captured for accurate delivery')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLocating = false);
    }
  }

  Future<void> _applyCoupon() async {
    if (couponController.text.trim().isEmpty) return;

    setState(() {
      isApplyingCoupon = true;
      couponMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/coupons/validate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': couponController.text.trim()}),
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          discountPercent = (data['discount_percent'] as num).toDouble();
          appliedCoupon = data['code'];
          couponMessage = '✓ ${data['discount_percent']}% discount applied!';
        });
      } else {
        setState(() {
          discountPercent = 0;
          appliedCoupon = null;
          couponMessage = data['error'] ?? 'Invalid coupon';
        });
      }
    } catch (e) {
      setState(() => couponMessage = 'Could not check coupon, try again');
    } finally {
      setState(() => isApplyingCoupon = false);
    }
  }

  Future<void> processPayment() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        houseController.text.isEmpty ||
        areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required details')),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final fullAddress = '${houseController.text}, ${areaController.text}';
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.currentUser?['id'],
          'customer_name': nameController.text,
          'customer_phone': phoneController.text,
          'customer_address': fullAddress,
          'house_details': houseController.text,
          'area_details': areaController.text,
          'latitude': latitude,
          'longitude': longitude,
          'coupon_code': appliedCoupon,
          'discount_amount': discountAmount,
          'items': widget.cart,
          'total': finalTotal,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLocating ? null : _useCurrentLocation,
                icon: isLocating
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        latitude != null ? Icons.check_circle : Icons.my_location,
                        color: latitude != null ? Colors.green : const Color(0xFFFF6B35),
                      ),
                label: Text(
                  latitude != null ? 'Location captured ✓' : 'Use my current location',
                  style: TextStyle(color: latitude != null ? Colors.green : const Color(0xFFFF6B35)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: latitude != null ? Colors.green : const Color(0xFFFF6B35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: houseController,
              decoration: InputDecoration(
                labelText: 'House / Flat / Plot No. *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: areaController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Area / Full Address *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Have a coupon?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isApplyingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: isApplyingCoupon
                      ? const SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
            if (couponMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                couponMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: discountPercent > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                      Text('₹${widget.total}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  if (discountPercent > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount ($appliedCoupon):', style: const TextStyle(fontSize: 14, color: Colors.green)),
                        Text('−₹${discountAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: Colors.green)),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${finalTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
