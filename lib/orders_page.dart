import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';

class OrdersPage extends StatefulWidget {
  final int userId;

  const OrdersPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$kApiBaseUrl/users/${widget.userId}/orders'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = List<Map<String, dynamic>>.from(data['orders']);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Could not load your orders';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Could not connect to server';
        isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'confirmed':
        return 'Confirmed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: RefreshIndicator(
        onRefresh: fetchOrders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
              ))
            : errorMessage != null
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Icon(Icons.wifi_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(errorMessage!, style: TextStyle(color: Colors.grey[600])),
                      ),
                    ],
                  )
                : orders.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No orders yet',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              'Your order history will show up here',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final status = order['status'] ?? 'pending';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${order['id']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${order['total_amount']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Payment: ${order['payment_status'] ?? 'pending'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  if (order['created_at'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      DateTime.parse(order['created_at']).toLocal().toString().split('.')[0],
                                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
