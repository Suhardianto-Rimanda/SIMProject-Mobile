import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kitchen_provider.dart';
import '../../models/kitchen_model.dart';

class KitchenQueuePage extends StatefulWidget {
  const KitchenQueuePage({super.key});

  @override
  State<KitchenQueuePage> createState() => _KitchenQueuePageState();
}

class _KitchenQueuePageState extends State<KitchenQueuePage> {
  @override
  void initState() {
    super.initState();
    _refreshQueue();
  }

  void _refreshQueue() {
    Provider.of<KitchenProvider>(context, listen: false).fetchQueue();
  }

  // --- UPDATE STATUS ---
  void _updateStatus(int orderId, String currentStatus) {
    String nextStatus = 'cooking';
    if (currentStatus == 'cooking') nextStatus = 'completed';

    // Konfirmasi jika selesai
    if (nextStatus == 'completed') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Selesai Masak?"),
          content: const Text("Pesanan akan ditandai selesai dan hilang dari antrian."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Provider.of<KitchenProvider>(context, listen: false).updateOrderStatus(orderId, nextStatus);
              },
              child: const Text("Ya, Selesai"),
            )
          ],
        ),
      );
    } else {
      // Langsung update jika pending -> cooking
      Provider.of<KitchenProvider>(context, listen: false).updateOrderStatus(orderId, nextStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<KitchenProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshQueue,
        backgroundColor: Colors.orange[800],
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: prov.isLoadingQueue
          ? const Center(child: CircularProgressIndicator())
          : prov.tasks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
            const SizedBox(height: 16),
            const Text("Semua pesanan selesai!", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prov.tasks.length,
        itemBuilder: (ctx, i) {
          final group = prov.tasks[i];
          return _buildMenuTaskCard(group);
        },
      ),
    );
  }

  Widget _buildMenuTaskCard(KitchenTaskGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        children: [
          // Header: Nama Menu & Total Qty
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(group.menuName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                  child: Text("${group.totalQty} Porsi", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          // List Pesanan Individual
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.orders.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final order = group.orders[i];
              final isCooking = order.status == 'cooking';

              return ListTile(
                title: Text(order.invoice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(order.customer, style: TextStyle(color: Colors.grey[600])),
                trailing: ElevatedButton.icon(
                  onPressed: () => _updateStatus(order.id, order.status),
                  icon: Icon(
                      isCooking ? Icons.check : Icons.local_fire_department,
                      size: 16
                  ),
                  label: Text(isCooking ? "Selesai" : "Masak"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCooking ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}