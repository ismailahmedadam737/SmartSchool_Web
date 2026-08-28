import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UsersPage extends StatefulWidget {
  final String currentRole;
  const UsersPage({super.key, required this.currentRole});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final String baseUrl = "https://smartschool-web.onrender.com/api/users";

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = "User";

  List users = [];
  bool isLoading = false;

  bool get isSuperAdmin => widget.currentRole.trim().toLowerCase().contains('super');

  List<String> get availableRoles => isSuperAdmin
      ? ["SuperAdmin", "Admin", "Cashier", "User"]
      : ["Admin", "Cashier", "User"];

  List get visibleUsers {
    if (isSuperAdmin) return users;
    return users.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      return !role.contains('super');
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        setState(() {
          users = data is List ? data : (data['users'] ?? []);
        });
      } else {
        debugPrint("Error Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
  }

  Future<void> createUser() async {
    if (usernameController.text.trim().isEmpty || passwordController.text.trim().isEmpty) return;
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text.trim(),
          "password": passwordController.text.trim(),
          "role": selectedRole,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        usernameController.clear();
        passwordController.clear();
        selectedRole = "User";
        if (mounted) Navigator.pop(context);
        await fetchUsers();
      }
    } catch (e) {
      debugPrint("Error creating: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> deleteUser(String id, String userRole) async {
    if (!isSuperAdmin && userRole.toLowerCase().contains('super')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ma tirtiri kartid akoon SuperAdmin ah!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await http.delete(Uri.parse("$baseUrl/$id"));
      await fetchUsers();
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  Color _getRoleColor(String? role) {
    String r = (role ?? '').toLowerCase();
    if (r.contains('super')) return const Color(0xFF6A11CB);
    if (r.contains('admin')) return Colors.blue;
    if (r.contains('cashier') || r.contains('qasnaji')) return Colors.teal;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = visibleUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Users & Roles Management", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSuperAdmin ? "SuperAdmin Control Panel" : "Admin User Management",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSuperAdmin 
                      ? "SuperAdmin | Admin | Cashier | User" 
                      : "Admin | Cashier | Users ", 
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 20, 18, 10),
            child: Text("Users List", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: listToShow.length,
                itemBuilder: (context, index) {
                  final user = listToShow[index];
                  final role = user['role']?.toString() ?? 'User';
                  final roleColor = _getRoleColor(role);

                  return Card(
                    elevation: 0.5,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor.withOpacity(0.12), 
                        child: Icon(Icons.person, color: roleColor),
                      ),
                      title: Text(user['username'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: roleColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => deleteUser(
                          user['id']?.toString() ?? user['_id']?.toString() ?? '',
                          role,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => _showSquareForm(context),
          label: const Text("NEW USER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showSquareForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add New User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildInput(usernameController, "Username", Icons.person),
                const SizedBox(height: 12),
                _buildInput(passwordController, "Password", Icons.lock, isObscure: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.security, color: Color(0xFF6A11CB)),
                      items: availableRoles.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            r == 'User' ? 'User (Arday / Waalid)' : r,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                          setState(() => selectedRole = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: isLoading ? null : createUser,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]), borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CREATE USER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        hintText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}