import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';

class TeachersPage extends StatefulWidget {
  final String userRole;
  const TeachersPage({super.key, this.userRole = ''});

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

  bool get isTeacherRole => widget.userRole.trim().toLowerCase() == 'teacher';

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
        List<Map<String, String>> newFetched = List.from(data);
        for (var localTeacher in teachers) {
          bool exists = newFetched.any((f) => 
            (f['name'] == localTeacher['name'] && f['phone'] == localTeacher['phone']) ||
            (localTeacher['id'] != null && localTeacher['id']!.isNotEmpty && f['id'] == localTeacher['id'])
          );
          if (!exists) {
            newFetched.insert(0, localTeacher);
          }
        }
        teachers = newFetched;
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
      "id": editingIndex != null ? (teachers[editingIndex!]['id'] ?? '') : DateTime.now().millisecondsSinceEpoch.toString(),
      "name": nameController.text,
      "district": districtController.text,
      "phone": phoneController.text,
      "exp": expController.text,
      "level": levelController.text,
    };

    setState(() {
      if (editingIndex == null) {
        teachers.insert(0, teacherData);
      } else {
        teachers[editingIndex!] = teacherData;
      }
    });

    bool success;
    if (editingIndex != null) {
      final String? teacherId = teacherData['id'];
      if (teacherId != null && teacherId.isNotEmpty) {
        success = await ApiService.updateTeacher(teacherId, teacherData);
      } else {
        success = false;
      }
    } else {
      success = await ApiService.registerTeacher(teacherData);
    }

    _clearFields();
    if (success) {
      await _fetchTeachers();
    }
    _showSnackBar(
      editingIndex == null ? "Si guul leh ayaa loo kaydiyay" : "Si guul leh ayaa loo cusboonaysiiyay", 
      Colors.green
    );
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildTeacherForm(),
                ),
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildTeacherList(isDesktop: true),
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildTeacherForm(),
                  const SizedBox(height: 16),
                  _buildTeacherList(isDesktop: false),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTeacherForm() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            // Teacher Role-ka waxa uu keliya geli karaa diiwaangelinta cusub, kuma cusboonaysiinayo
            if (editingIndex != null && !isTeacherRole)
              TextButton(onPressed: _clearFields, child: const Text("Jooji Wax ka bedelka", style: TextStyle(color: Colors.red))),
            const SizedBox(height: 10),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherList({required bool isDesktop}) {
    final listWidget = isLoading 
      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF512F)))
      : teachers.isEmpty 
        ? const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Wax xog ah lama helin"),
          ))
        : ListView.builder(
            shrinkWrap: !isDesktop,
            physics: isDesktop ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: teachers.length,
            itemBuilder: (context, index) => _teacherCard(teachers[index], index),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Liiska Macalimiinta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (isDesktop)
          Expanded(child: listWidget)
        else
          listWidget,
      ],
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
    // Teacher role-ku kaliya diiwaangelinta cusub buu samayn karaa (ma update-gareynkaro)
    bool isUpdateMode = editingIndex != null && !isTeacherRole;
    return ElevatedButton(
      onPressed: isLoading ? null : (isTeacherRole && editingIndex != null ? null : _saveTeacher),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isTeacherRole && editingIndex != null
              ? [Colors.grey, Colors.grey]
              : [const Color(0xFFFF512F), const Color(0xFFDD2476)]),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          height: 55,
          alignment: Alignment.center,
          child: Text(
            isUpdateMode ? "Cusboonaysii Xogta" : "Kaydi Macalinka", 
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
            // Teacher role-ku ma Edit-gareynkaro macalimiinta kale (is-diiwaangelin uun)
            if (!isTeacherRole)
              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editTeacher(index)),
            if (widget.userRole.toLowerCase() != 'teacher')
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTeacher(index)),
          ],
        ),
      ),
    );
  }
}