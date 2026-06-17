import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController expController = TextEditingController();
  final TextEditingController levelController = TextEditingController();

  int? editingIndex;
  List<Map<String, String>> teachers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  // 1. Soo aqri Macalimiinta
  Future<void> _fetchTeachers() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getAllTeachers();
      setState(() {
        teachers = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Khalad ayaa dhacay marka xogta la soo aqrinayay", Colors.red);
    }
  }

  // 2. Kaydi ama Cusboonaysii (Halkan ayaa la saxay)
  Future<void> _saveTeacher() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      _showSnackBar("Fadlan buuxi Magaca iyo Taleefanka", Colors.orange);
      return;
    }

    Map<String, String> teacherData = {
      "name": nameController.text,
      "district": districtController.text,
      "phone": phoneController.text,
      "exp": expController.text,
      "level": levelController.text,
    };

    setState(() => isLoading = true);

    bool success;
    if (editingIndex != null) {
      // Halkan waxaan ka soo qaadaynaa ID-ga saxda ah si aan duplicate u dhicin
      final String? teacherId = teachers[editingIndex!]['id'];
      if (teacherId != null) {
        success = await ApiService.updateTeacher(teacherId, teacherData);
      } else {
        success = false;
      }
    } else {
      success = await ApiService.registerTeacher(teacherData);
    }

    if (success) {
      _clearFields();
      await _fetchTeachers();
      _showSnackBar(
        editingIndex == null ? "Si guul leh ayaa loo kaydiyay" : "Si guul leh ayaa loo cusboonaysiiyay", 
        Colors.green
      );
    } else {
      setState(() => isLoading = false);
      _showSnackBar("Hawshu ma guulaysan", Colors.red);
    }
  }

  // 3. Tirtir Macalinka
  Future<void> _deleteTeacher(int index) async {
    final String? id = teachers[index]['id'];
    if (id == null) return;

    bool confirm = await _showDeleteDialog();
    if (confirm) {
      setState(() => isLoading = true);
      bool success = await ApiService.deleteTeacher(id);
      if (success) {
        await _fetchTeachers();
        _showSnackBar("Waa la tirtiray", Colors.blueGrey);
      } else {
        setState(() => isLoading = false);
        _showSnackBar("Tirtiristu ma guulaysan", Colors.red);
      }
    }
  }

  void _editTeacher(int index) {
    setState(() {
      editingIndex = index;
      nameController.text = teachers[index]['name'] ?? "";
      districtController.text = teachers[index]['district'] ?? "";
      phoneController.text = teachers[index]['phone'] ?? "";
      levelController.text = teachers[index]['level'] ?? "";
      expController.text = teachers[index]['exp'] ?? "";
    });
  }

  void _clearFields() {
    nameController.clear();
    districtController.clear();
    phoneController.clear();
    expController.clear();
    levelController.clear();
    setState(() => editingIndex = null);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<bool> _showDeleteDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ma hubtaa?"),
        content: const Text("Xogtan dib looma soo celin karo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Maya")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Haa, Tirtir", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  void _showTeacherDetails(Map<String, String> teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(teacher['name'] ?? "Xogta Macalinka", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow(Icons.phone, "Phone:", teacher['phone'] ?? "N/A"),
            _detailRow(Icons.school, "Education:", teacher['level'] ?? "N/A"),
            _detailRow(Icons.history, "Experience:", teacher['exp'] ?? "N/A"),
            _detailRow(Icons.location_city, "District:", teacher['district'] ?? "N/A"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Xidh")),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF512F)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Qaybta Input-ka (Bidix)
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editingIndex == null ? "Diiwaangeli Macalin" : "Cusboonaysii Xogta", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))
                    ),
                    const SizedBox(height: 25),
                    _inputField("Magaca Buuxa", Icons.person_add_alt_1, nameController),
                    _inputField("Degmada (District)", Icons.location_city, districtController),
                    _inputField("Taleefanka", Icons.phone_android, phoneController),
                    _inputField("Heerka Waxbarasho", Icons.school, levelController),
                    _inputField("Khibradda (Experience)", Icons.workspace_premium, expController),
                    const SizedBox(height: 20),
                    if (editingIndex != null)
                      TextButton(onPressed: _clearFields, child: const Text("Jooji Wax ka bedelka", style: TextStyle(color: Colors.red))),
                    const SizedBox(height: 10),
                    _saveButton(),
                  ],
                ),
              ),
            ),
          ),

          // Qaybta Liiska (Midig)
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Liiska Macalimiinta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF512F)))
                    : teachers.isEmpty 
                      ? const Center(child: Text("Wax xog ah lama helin"))
                      : ListView.builder(
                          itemCount: teachers.length,
                          itemBuilder: (context, index) => _teacherCard(teachers[index], index),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFFF512F)),
          filled: true,
          fillColor: const Color(0xFFF8F9FD),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _saveTeacher,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          height: 55,
          alignment: Alignment.center,
          child: Text(
            editingIndex == null ? "Kaydi Macalinka" : "Cusboonaysii Xogta", 
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }

  Widget _teacherCard(Map<String, String> teacher, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => _showTeacherDetails(teacher),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF512F),
          child: Text(teacher['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(teacher['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${teacher['district']} | ${teacher['phone']}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editTeacher(index)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTeacher(index)),
          ],
        ),
      ),
    );
  }
}