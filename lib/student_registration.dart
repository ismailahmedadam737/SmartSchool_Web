import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:iftiinshe/Service/api_service.dart';
import 'package:iftiinshe/models/student_model.dart';

class StudentRegistrationPage extends StatefulWidget {
  const StudentRegistrationPage({super.key});

  @override
  State<StudentRegistrationPage> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<StudentRegistrationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _neighborController = TextEditingController();
  
  final ScrollController _classScrollController = ScrollController();

  List<String> _classes = [];
  String? _selectedClass; 
  String? _viewingClass;   
  List<Map<String, String>> students = [];
  bool _isSyncing = false; 

  @override
  void initState() {
    super.initState();
    _loadDataFromDatabase(); 
  }

  Future<void> _loadDataFromDatabase() async {
    setState(() => _isSyncing = true);
    try {
      final List<StudentModel> fetched = await ApiService.getAllStudents();
      setState(() {
        students = fetched.map((s) => {
          "id": s.id.toString(),
          "name": s.name,
          "phone": s.phone,
          "district": s.district,
          "neighbor": s.neighbor,
          "class": s.className,
        }).toList();

        _classes = fetched
            .map((s) => s.className)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        
        _classes.sort(); 
      });
    } catch (e) {
      debugPrint("Error loading students: $e");
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  int? _editingIndex;

  void _addNewClassDialog() {
    TextEditingController classController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Class"),
        content: TextField(
          controller: classController,
          decoration: const InputDecoration(hintText: "Tusaale: 9A, 10B..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ka noqo")),
          ElevatedButton(
            onPressed: () {
              if (classController.text.isNotEmpty) {
                setState(() {
                  String newClass = classController.text.toUpperCase();
                  if (!_classes.contains(newClass)) _classes.add(newClass);
                  _selectedClass = newClass;
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Ku dar"),
          ),
        ],
      ),
    );
  }

  void _saveStudent() async {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty && _selectedClass != null) {
      StudentModel studentObj = StudentModel(
        name: _nameController.text,
        phone: _phoneController.text,
        district: _districtController.text,
        neighbor: _neighborController.text,
        className: _selectedClass!, fullName: '',
      );

      setState(() => _isSyncing = true);
      bool isSaved = await ApiService.registerStudent(studentObj);

      if (isSaved) {
        await _loadDataFromDatabase(); 
        _clearFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Si guul leh ayaa loo kaydiyey")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Qalad ayaa dhacay!")),
        );
      }
      
      setState(() {
        _isSyncing = false;
        _editingIndex = null;
      });
    }
  }

  void _deleteStudentFromDb(String id) async {
    setState(() => _isSyncing = true);
    bool isDeleted = await ApiService.deleteStudent(id);
    if (isDeleted) {
      await _loadDataFromDatabase();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Ardayga waa la tirtiray")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Tirtirku ma suurtagalin!")),
      );
    }
    setState(() => _isSyncing = false);
  }

  void _clearFields() {
    _nameController.clear();
    _phoneController.clear();
    _districtController.clear();
    _neighborController.clear();
    _selectedClass = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editingIndex != null ? "Cusboonaysii Ardayga" : "Add New Student", 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    const SizedBox(height: 25),
                    _buildClassDropdown(),
                    const SizedBox(height: 15),
                    _buildInputField("Magaca Buuxa", Icons.person_outline, _nameController),
                    _buildInputField("Taleefanka", Icons.phone_android_outlined, _phoneController),
                    _buildInputField("Degmada", Icons.map_outlined, _districtController),
                    _buildInputField("Xaafadda", Icons.home_work_outlined, _neighborController),
                    const SizedBox(height: 30),
                    _isSyncing 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveStudent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(0), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            height: 55,
                            alignment: Alignment.center,
                            child: Text(_editingIndex == null ? "Kaydi Xogta" : "Cusboonaysii", 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Dooro Fasal si aad u aragto Ardayda", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      IconButton.filled(
                        onPressed: _addNewClassDialog, 
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF6A11CB)),
                        tooltip: "Add New Class",
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent) {
                        final newOffset = _classScrollController.offset + pointerSignal.scrollDelta.dy;
                        _classScrollController.jumpTo(newOffset.clamp(0.0, _classScrollController.position.maxScrollExtent));
                      }
                    },
                    child: RawScrollbar(
                      controller: _classScrollController,
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(10),
                      thumbColor: const Color(0xFF6A11CB).withOpacity(0.3),
                      child: Container(
                        height: 130,
                        padding: const EdgeInsets.only(bottom: 15),
                        child: ListView.builder(
                          controller: _classScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _classes.length,
                          itemBuilder: (context, index) {
                            bool isSelected = _viewingClass == _classes[index];
                            return GestureDetector(
                              onTap: () => setState(() => _viewingClass = _classes[index]),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 110,
                                margin: const EdgeInsets.only(right: 15, top: 5, bottom: 5),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]) : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    if (isSelected) BoxShadow(color: const Color(0xFF6A11CB).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                                    else BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)
                                  ],
                                  border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.school, color: isSelected ? Colors.white : Colors.blueGrey, size: 28),
                                    const SizedBox(height: 8),
                                    Text(_classes[index], 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.white : Colors.black87)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: _isSyncing 
                        ? const Center(child: CircularProgressIndicator())
                        : _viewingClass == null 
                          ? const Center(child: Text("Fadlan doorto mid ka mid ah fasallada kore"))
                          : _buildFilteredStudentList(),
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

  Widget _buildFilteredStudentList() {
    final filteredList = students.where((s) => s['class'] == _viewingClass).toList();
    if (filteredList.isEmpty) return const Center(child: Text("Fasalkan arday kuma jirto"));

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final student = filteredList[index];
        int actualIndex = students.indexOf(student);
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
          child: ListTile(
            onTap: () => _showStudentDetails(student),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6A11CB).withOpacity(0.1),
              child: Text(student['name']![0], style: const TextStyle(color: Color(0xFF6A11CB), fontWeight: FontWeight.bold)),
            ),
            title: Text(student['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(student['phone']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => setState(() => _startUpdate(actualIndex))),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red), 
                  onPressed: () {
                    if (student['id'] != null) {
                       _deleteStudentFromDb(student['id']!);
                    }
                  }
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startUpdate(int index) {
    _editingIndex = index;
    _nameController.text = students[index]['name']!;
    _phoneController.text = students[index]['phone']!;
    _districtController.text = students[index]['district']!;
    _neighborController.text = students[index]['neighbor']!;
    _selectedClass = students[index]['class']!;
  }

  void _showStudentDetails(Map<String, String> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text(student['name']!, style: const TextStyle(fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            _detailRow("Fasalka:", student['class']!),
            _detailRow("Taleefanka:", student['phone']!),
            _detailRow("Degmada:", student['district']!),
            _detailRow("Xaafadda:", student['neighbor']!),
            const Divider(),
          ],
        ),
        actions: [
          Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Xidh", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClass,
          hint: Text(_classes.isEmpty ? "Fasallo ma jiraan" : "Xulo Fasalka"),
          isExpanded: true,
          items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _selectedClass = val),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6A11CB)),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}