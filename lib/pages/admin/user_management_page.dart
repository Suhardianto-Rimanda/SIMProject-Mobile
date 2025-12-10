import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // Controller pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // State untuk Filter Role (Default: All)
  String _selectedRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchUsers()
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- DIALOG DETAIL ---
  void _showDetailDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
              child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role)),
            ),
            const SizedBox(width: 12),
            const Text("Detail Staff"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow("ID System", "#${user.id}"),
            const Divider(),
            _detailRow("Nama Lengkap", user.fullName),
            const Divider(),
            _detailRow("Username", user.username),
            const Divider(),
            _detailRow("Role", user.role.toUpperCase(), isBadge: true, role: user.role),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tutup")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBadge = false, String? role}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          isBadge
              ? _buildRoleBadge(role!)
              : Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // --- DIALOG FORM (ADD/EDIT) ---
  void _showUserDialog({User? userToEdit}) {
    final isEdit = userToEdit != null;
    final fullNameCtrl = TextEditingController(text: userToEdit?.fullName ?? '');
    final usernameCtrl = TextEditingController(text: userToEdit?.username ?? '');
    final passwordCtrl = TextEditingController();
    String role = userToEdit?.role ?? 'cashier';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit Staff" : "Tambah Pegawai"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                decoration: InputDecoration(
                  labelText: isEdit ? "Password (Isi jika ubah)" : "Password",
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                  DropdownMenuItem(value: "cashier", child: Text("Cashier")),
                  DropdownMenuItem(value: "kitchen", child: Text("Kitchen")),
                ],
                onChanged: (val) => role = val!,
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isEdit ? Colors.orange : const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () async {
              if (fullNameCtrl.text.isEmpty || usernameCtrl.text.isEmpty) return;

              final body = {
                "full_name": fullNameCtrl.text,
                "username": usernameCtrl.text,
                "role": role,
              };
              if (passwordCtrl.text.isNotEmpty) body["password"] = passwordCtrl.text;

              try {
                if (isEdit) {
                  await Provider.of<AdminProvider>(context, listen: false).editUser(userToEdit.id, body);
                } else {
                  await Provider.of<AdminProvider>(context, listen: false).addUser(body);
                }
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Berhasil update" : "Berhasil tambah")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
              }
            },
            child: Text(isEdit ? "Update" : "Simpan"),
          )
        ],
      ),
    );
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text("Hapus ${user.fullName}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false).deleteUser(user.id);
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User dihapus")));
              } catch (e) {
                Navigator.pop(ctx);
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
    final adminProv = Provider.of<AdminProvider>(context);

    // --- LOGIC FILTER GANDA (SEARCH + ROLE) ---
    final filteredUsers = adminProv.users.where((user) {
      // 1. Filter Text
      final matchText = user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Filter Role
      final matchRole = _selectedRoleFilter == 'All' ||
          user.role.toLowerCase() == _selectedRoleFilter.toLowerCase();

      return matchText && matchRole;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Kelola Staff / User", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // HEADER AREA (Search + Filter)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // 1. SEARCH BAR
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Cari nama atau username...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. FILTER BUTTONS (Horizontal Scroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All", "Semua"),
                      _buildFilterChip("Admin", "Admin"),
                      _buildFilterChip("Cashier", "Kasir"),
                      _buildFilterChip("Kitchen", "Dapur"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LIST USERS
          Expanded(
            child: adminProv.isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _buildUserCard(filteredUsers[i]),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Tombol Filter (Chip Style)
  Widget _buildFilterChip(String roleKey, String label) {
    final isSelected = _selectedRoleFilter == roleKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedRoleFilter = roleKey;
          });
        },
        selectedColor: Colors.redAccent.withOpacity(0.1), // Warna Admin
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.redAccent : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? Colors.redAccent : Colors.grey[300]!,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Tidak ada data user ditemukan",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
          child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role), size: 22),
        ),
        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Row(
          children: [
            Text("@${user.username}", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(width: 8),
            _buildRoleBadge(user.role),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          onSelected: (value) {
            if (value == 'detail') _showDetailDialog(user);
            if (value == 'edit') _showUserDialog(userToEdit: user);
            if (value == 'delete') _confirmDelete(user);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            _buildPopupItem('detail', Icons.visibility_outlined, "Detail", Colors.blue),
            _buildPopupItem('edit', Icons.edit_outlined, "Edit", Colors.orange),
            _buildPopupItem('delete', Icons.delete_outline, "Hapus", Colors.red),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'cashier': return Colors.blue;
      case 'kitchen': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin': return Icons.admin_panel_settings;
      case 'cashier': return Icons.point_of_sale;
      case 'kitchen': return Icons.restaurant;
      default: return Icons.person;
    }
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getRoleColor(role).withOpacity(0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.w600, fontSize: 10),
      ),
    );
  }
}