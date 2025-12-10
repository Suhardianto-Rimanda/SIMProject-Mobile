import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'kitchen_stock_page.dart';
import 'kitchen_queue_page.dart';

class KitchenHomePage extends StatefulWidget {
  const KitchenHomePage({super.key});

  @override
  State<KitchenHomePage> createState() => _KitchenHomePageState();
}

class _KitchenHomePageState extends State<KitchenHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const KitchenStockPage(),
    const KitchenQueuePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? "Stok & Belanja" : "Antrian Masak",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[800], // Warna Oranye untuk Kitchen
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stok Gudang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.soup_kitchen),
            label: 'Antrian Masak',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange[800],
        onTap: _onItemTapped,
      ),
    );
  }
}