// lib/screens/admin/admin_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:success_motors/Admin/active_users.dart';
import 'package:success_motors/Admin/add_product.dart';
import 'package:success_motors/Admin/all_orders.dart';
import 'package:success_motors/Admin/deleted_accounts.dart';
import 'package:success_motors/Admin/delivery_guys_management.dart';
import 'package:success_motors/Admin/garage/garage_bookings_admin.dart';
import 'package:success_motors/Admin/loan/admin_loan_applications_screen.dart';
import 'package:success_motors/Admin/rental_cars/add_rental_car.dart';
import 'package:success_motors/Admin/rental_cars/all_rental_cars_screen.dart';
import 'package:success_motors/Admin/rental_cars/rental_bookings_admin_screen.dart';
import 'package:success_motors/Admin/send_promotion_screen.dart';
import 'package:success_motors/Admin/all_products_screen.dart';
import 'package:success_motors/Admin/statistics_screen.dart';
import 'package:success_motors/Admin/admin_categories_screen.dart';
// NEW IMPORTS FOR LIVE CHAT
import 'package:success_motors/Admin/live_chats_list_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  AdminPanelScreen({super.key});

  final List<Map<String, dynamic>> adminMenu = [
    {
      'title': 'All Orders',
      'icon': Icons.shopping_bag_outlined,
      'color': const Color(0xFF2E7D32),
      'subtitle': 'View & manage orders',
      'screen': AllOrdersScreen(),
    },
    {
      'title': 'Add New Car',
      'icon': Icons.add_box_outlined,
      'color': Colors.orange,
      'subtitle': 'Add new items',
      'screen': const AddProductScreen(),
    },
    {
      'title': 'All Products',
      'icon': Icons.inventory_2_outlined,
      'color': Colors.indigo,
      'subtitle': 'View all products',
      'screen': const AllProductsScreen(),
    },
    {
      'title': 'Statistics',
      'icon': Icons.bar_chart_outlined,
      'color': Colors.teal,
      'subtitle': 'Revenue, users & more',
      'screen': const StatisticsScreen(),
    },
    {
      'title': 'Categories',
      'icon': Icons.category_outlined,
      'color': Colors.deepPurple,
      'subtitle': 'Manage product categories',
      'screen': AdminCategoriesScreen(),
    },
    {
      'title': 'Active Users',
      'icon': Icons.people_alt_outlined,
      'color': Colors.blue,
      'subtitle': 'Registered users',
      'screen': const ActiveUsersScreen(),
    },
    {
      'title': 'Deleted Accounts',
      'icon': Icons.person_off_outlined,
      'color': Colors.redAccent,
      'subtitle': 'Removed accounts',
      'screen': const DeletedAccountsScreen(),
    },
    {
      'title': 'Delivery Guys',
      'icon': Icons.delivery_dining,
      'color': Colors.purple,
      'subtitle': 'Manage riders',
      'screen': const DeliveryGuysManagementScreen(),
    },
    {
      'title': 'Send Promotion',
      'icon': Icons.campaign_outlined,
      'color': Colors.teal,
      'subtitle': 'Push notifications',
      'screen': const SendPromotionScreen(),
    },
    // NEW CARD: Live Chats
    {
      'title': 'Live Chats',
      'icon': Icons.chat_outlined,
      'color': const Color(0xFF2E7D32), // Matches your primary green
      'subtitle': 'Customer support chats',
      'screen': const LiveChatsListScreen(),
    },
    {
      'title': 'Garage Bookings',
      'icon': Icons.calendar_month_outlined,
      'color': Colors.deepOrange,
      'subtitle': 'Manage service bookings',
      'screen': const GarageBookingsAdminScreen(),
    },
    {
      'title': 'Rental Bookings',
      'icon': Icons.directions_car_filled_outlined,
      'color': Colors.deepOrangeAccent,
      'subtitle': 'Manage car rentals',
      'screen': const RentalBookingsAdminScreen(),
    },
    // Example card in your admin menu
    {
      'title': 'Add Rental Car',
      'icon': Icons.directions_car_filled,
      'color': Colors.orange,
      'subtitle': 'Add cars available for rent',
      'screen': const AddRentalCarScreen(),
    },
    {
      'title': 'Add Rental Car',
      'icon': Icons.directions_car,
      'color': Colors.green,
      'subtitle': 'All Rental Cars Listed',
      'screen': const AllRentalCarsScreen(),
    },
    {
      'title': 'Loan Applications',
      'icon': Icons.money_rounded,
      'color': Colors.purple,
      'subtitle': 'Review & Approve Loans',
      'screen': const AdminLoanApplicationsScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width > 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Success Motors Admin',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Welcome back, Boss!'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
          ),
          itemCount: adminMenu.length,
          itemBuilder: (context, index) {
            final item = adminMenu[index];
            final color = item['color'] as Color;

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['screen'] as Widget),
                );
              },
              child: Card(
                elevation: 8,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 38,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
