import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/ingredient_model.dart';

class IngredientManagementPage extends StatefulWidget {
  const IngredientManagementPage({super.key});

  @override
  State<IngredientManagementPage> createState() => _IngredientManagementPageState();
}

class _IngredientManagementPageState extends State<IngredientManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchIngredients()
    );
  }

  // --- DIALOG FORM (TAMBAH/EDIT) ---
  void _showIngredientDialog({Ingredient? ingredient}) {
    final isEdit = ingredient != null;
    final nameCtrl = TextEditingController(text: ingredient?.name ?? '');
    final unitCtrl = TextEditingController(text: ingredient?.unit ?? '');
    final purchaseUnitCtrl = TextEditingController(text: ingredient?.purchaseUnit ?? '');
    final conversionCtrl = TextEditingController(text: ingredient?.conversionRate.toString() ?? '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit Bahan Baku" : "Tambah Bahan Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nama Bahan", border: OutlineInputBorder(), hintText: "Contoh: Telur"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: "Satuan Resep", border: OutlineInputBorder(), hintText: "gr, ml, butir"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: purchaseUnitCtrl,
                      decoration: const InputDecoration(labelText: "Satuan Beli", border: OutlineInputBorder(), hintText: "Kg, Karung, Rak"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conversionCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Rasio Konversi",
                    border: OutlineInputBorder(),
                    helperText: "Contoh: 1 Kg = 1000 gr (Isi 1000)"
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || unitCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama dan Satuan Resep wajib diisi")));
                return;
              }

              final body = {
                "name": nameCtrl.text,
                "unit": unitCtrl.text, // Satuan dasar (dipakai di resep)
                "purchase_unit": purchaseUnitCtrl.text.isNotEmpty ? purchaseUnitCtrl.text : unitCtrl.text,
                "conversion_rate": double.tryParse(conversionCtrl.text) ?? 1,
              };

              try {
                final prov = Provider.of<AdminProvider>(context, listen: false);
                if (isEdit) {
                  await prov.updateIngredient(ingredient!.id, body);
                } else {
                  await prov.addIngredient(body);
                }
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Bahan diupdate" : "Bahan ditambahkan")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  void _confirmDelete(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Bahan?"),
        content: Text("Bahan '${ingredient.name}' akan dihapus. Pastikan tidak ada resep yang menggunakannya."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false).deleteIngredient(ingredient.id);
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                Navigator.pop(ctx); // Tutup dialog dulu
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
              }
            },
            child: const Text("Hapus"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Master Bahan Baku"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showIngredientDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Tambah"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),
          )
        ],
      ),
      body: prov.isLoadingIngredients
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.ingredients.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final ingredient = prov.ingredients[i];
          return _buildIngredientCard(ingredient);
        },
      ),
    );
  }

  Widget _buildIngredientCard(Ingredient ingredient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory_2, color: Colors.brown[400], size: 24),
        ),
        title: Text(
            ingredient.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            // Baris Stok
            Row(
              children: [
                Text(
                    "${ingredient.stock} ${ingredient.unit}",
                    style: TextStyle(
                        color: ingredient.stock < 10 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold
                    )
                ),
                const SizedBox(width: 8),
                Text(
                    "(Stok Unit Resep)",
                    style: TextStyle(color: Colors.grey[400], fontSize: 11)
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Baris Info Konversi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "1 ${ingredient.purchaseUnit} = ${ingredient.conversionRate} ${ingredient.unit}",
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          onSelected: (value) {
            if (value == 'edit') _showIngredientDialog(ingredient: ingredient);
            if (value == 'delete') _confirmDelete(ingredient);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.amber, size: 20),
                  SizedBox(width: 12),
                  Text('Edit Data'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Hapus'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}