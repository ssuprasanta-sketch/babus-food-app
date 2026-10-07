import 'package:flutter/material.dart';
import 'main.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final void Function(Map<String, dynamic> product) onAddToCart;
  final List<Map<String, dynamic>> cart;
  final Map<String, dynamic>? currentUser;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.onAddToCart,
    required this.cart,
    this.currentUser,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasImage = product['image_url'] != null && product['image_url'].toString().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B35),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? Image.network(
                      product['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.restaurant, size: 80, color: Colors.grey)),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.restaurant, size: 80, color: Colors.grey)),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] ?? '',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${product['price']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (product['category'] ?? 'veg').toString().toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    (product['description'] != null && product['description'].toString().isNotEmpty)
                        ? product['description']
                        : 'No description available for this item yet.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini cart bar — appears once something is in the cart, updates live
          if (widget.cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: buildMiniCartBar(
                context,
                widget.cart,
                widget.currentUser,
                onReturn: () => setState(() {}),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onAddToCart(product);
                    setState(() {}); // refresh mini cart bar with new count
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product['name']} added to cart!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    // Stay on this page — user can keep browsing or go back manually
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
