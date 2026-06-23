import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required String currentRole});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final String baseUrl = "https://smartschool-web.onrender.com/api/users";

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  String selectedRole = "Admin"; 
  final List<String> roles = ["Admin", "Cashier", "Parent"];

  List users = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        setState(() {
          users = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
  }

  Future<void> createUser() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) return;
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
        setState(() => selectedRole = "Admin");
        Navigator.pop(context);
        fetchUsers();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> deleteUser(String id) async {
    try {
      await http.delete(Uri.parse("$baseUrl/$id"));
      fetchUsers();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Row(
        children: [
          // Dhinaca Bidix: Sawir weyn
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=500&auto=format&fit=crop"), // Bedel URL-kan haddii aad rabto sawir kale
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Dhinaca Midig: List-ka Users-ka
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome Back!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Manage your team easily.", style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          elevation: 0.5,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1),
                              child: const Icon(Icons.person, color: Color(0xFF6A11CB)),
                            ),
                            title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Role: ${user['role']}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => deleteUser(user['id'].toString()),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
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
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 300,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      items: roles.map((String role) {
                        return DropdownMenuItem<String>(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (value) => setModalState(() => selectedRole = value!),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: isLoading ? null : createUser,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("CREATE USER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      textAlign: TextAlign.center,
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