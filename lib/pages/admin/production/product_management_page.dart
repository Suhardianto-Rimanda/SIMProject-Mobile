import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../models/product_model.dart';
import '../../../models/recipe_model.dart';
import '../../../models/ingredient_model.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final prov = Provider.of<AdminProvider>(context, listen: false);
      prov.fetchProducts();
      prov.fetchIngredientsList();
    });
  }

  // --- DIALOG PRODUK (Tambah/Edit) ---
  void _showProductDialog({Product? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toStringAsFixed(0) ?? '');
    String category = product?.category ?? 'Food';
    bool isActive = product?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit Menu" : "Tambah Menu Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nama Menu", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "Food", child: Text("Makanan")),
                  DropdownMenuItem(value: "Drink", child: Text("Minuman")),
                  DropdownMenuItem(value: "Snack", child: Text("Camilan")),
                ],
                onChanged: (val) => category = val!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Harga Jual (Rp)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<bool>(
                value: isActive,
                decoration: const InputDecoration(labelText: "Status Jual", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: true, child: Text("Dijual (Aktif)")),
                  DropdownMenuItem(value: false, child: Text("Arsipkan (Non-Aktif)")),
                ],
                onChanged: (val) => isActive = val!,
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;

              final body = {
                "name": nameCtrl.text,
                "price": double.parse(priceCtrl.text),
                "category": category,
                "is_active": isActive
              };

              try {
                final prov = Provider.of<AdminProvider>(context, listen: false);
                if (isEdit) {
                  await prov.updateProduct(product!.id, body);
                } else {
                  await prov.addProduct(body);
                }
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Menu diupdate" : "Menu ditambahkan")));
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

  // --- DIALOG RESEP ---
  void _showRecipeDialog(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => RecipeManagerDialog(product: product),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Menu?"),
        content: Text("Menu '${product.name}' akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await Provider.of<AdminProvider>(context, listen: false).deleteProduct(product.id);
              if (mounted) Navigator.pop(ctx);
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
        title: const Text("Master Produk (Menu)"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Tambah"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            ),
          )
        ],
      ),
      body: prov.isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prov.products.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final product = prov.products[i];
          return _buildProductCard(product);
        },
      ),
    );
  }

  // WIDGET CARD PRODUK (REDESIGN)
  Widget _buildProductCard(Product product) {
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
            color: product.category == 'Food' ? Colors.orange[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            product.category == 'Food' ? Icons.restaurant : Icons.local_drink,
            color: product.category == 'Food' ? Colors.orange : Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                    "Rp ${product.price.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: product.isActive ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: product.isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2))
                  ),
                  child: Text(
                    product.isActive ? "Aktif" : "Non-Aktif",
                    style: TextStyle(
                        fontSize: 10,
                        color: product.isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
        // ACTION BUTTON (TITIK TIGA)
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          onSelected: (value) {
            if (value == 'recipe') _showRecipeDialog(product);
            if (value == 'edit') _showProductDialog(product: product);
            if (value == 'delete') _confirmDelete(product);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'recipe',
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.purple, size: 20),
                  SizedBox(width: 12),
                  Text('Atur Resep', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.amber, size: 20),
                  SizedBox(width: 12),
                  Text('Edit Menu', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Hapus', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET TERPISAH: DIALOG MANAGER RESEP
// ==========================================
class RecipeManagerDialog extends StatefulWidget {
  final Product product;
  const RecipeManagerDialog({super.key, required this.product});

  @override
  State<RecipeManagerDialog> createState() => _RecipeManagerDialogState();
}

class _RecipeManagerDialogState extends State<RecipeManagerDialog> {
  Ingredient? _selectedIngredient;
  final TextEditingController _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchRecipes(widget.product.id)
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🧪 Resep Produksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Menu: ${widget.product.name}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // List Resep Existing
            if (prov.isLoadingRecipes)
              const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
            else if (prov.currentRecipes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: const Text("Belum ada resep. Tambahkan bahan baku di bawah.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: prov.currentRecipes.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final recipe = prov.currentRecipes[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(recipe.ingredientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${recipe.quantity} ${recipe.unit}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () {
                          prov.deleteRecipeItem(recipe.recipeId, widget.product.id);
                        },
                      ),
                    );
                  },
                ),
              ),

            const Divider(thickness: 1, height: 30),

            // Form Tambah Bahan
            const Align(alignment: Alignment.centerLeft, child: Text("Tambah Bahan:", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<Ingredient>(
                    value: _selectedIngredient,
                    isExpanded: true,
                    hint: const Text("Pilih Bahan", style: TextStyle(fontSize: 12)),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(),
                    ),
                    items: prov.ingredientsList.map((ing) {
                      return DropdownMenuItem(value: ing, child: Text(ing.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      setState(() { _selectedIngredient = val; });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Jml",
                      suffixText: _selectedIngredient?.unit ?? '',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    if (_selectedIngredient == null || _qtyCtrl.text.isEmpty) return;

                    try {
                      await prov.addRecipeItem(
                          widget.product.id,
                          _selectedIngredient!.id,
                          double.parse(_qtyCtrl.text)
                      );
                      // Reset form
                      setState(() {
                        _selectedIngredient = null;
                        _qtyCtrl.clear();
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                    }
                  },
                )
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
      ],
    );
  }
}