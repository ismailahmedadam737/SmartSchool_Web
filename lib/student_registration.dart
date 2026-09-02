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
        List<Map<String, String>> newFetched = fetched.map((s) => {
          "id": s.idString,
          "name": s.name,
          "phone": s.phone,
          "district": s.district,
          "neighbor": s.neighbor,
          "class": s.className,
        }).toList();

        for (var localStudent in students) {
          bool exists = newFetched.any((f) => 
            (f['name'] == localStudent['name'] && f['phone'] == localStudent['phone']) ||
            (localStudent['id'] != null && localStudent['id']!.isNotEmpty && f['id'] == localStudent['id'])
          );
          if (!exists) {
            newFetched.insert(0, localStudent);
          }
        }

        students = newFetched;

        _classes = students
            .map((s) => s['class'] ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
        
        _classes.sort(); 

        if (_classes.isNotEmpty && (_viewingClass == null || !_classes.contains(_viewingClass))) {
          _viewingClass = _classes.first;
        }
      });
    } catch (e) {
      debugPrint("Error loading students: $e");
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  String? _editingStudentId;

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
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final district = _districtController.text.trim();
    final neighbor = _neighborController.text.trim();

    if (name.isEmpty || phone.isEmpty || _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fadlan buuxi Magaca, Taleefanka iyo Fasalka!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool isEditing = _editingStudentId != null && _editingStudentId!.isNotEmpty;
    debugPrint("🔍 _saveStudent called | isEditing: $isEditing | editingStudentId: $_editingStudentId");

    String newId = isEditing ? _editingStudentId! : DateTime.now().millisecondsSinceEpoch.toString();
    Map<String, String> newStudentMap = {
      "id": newId,
      "name": name,
      "phone": phone,
      "district": district,
      "neighbor": neighbor,
      "class": _selectedClass!,
    };

    String targetClass = _selectedClass!;

    setState(() {
      _viewingClass = targetClass;
      if (!_classes.contains(targetClass)) {
        _classes.add(targetClass);
        _classes.sort();
      }
      if (!isEditing) {
        students.insert(0, newStudentMap);
      } else {
        int idx = students.indexWhere((s) => s['id'] == _editingStudentId);
        if (idx != -1) {
          students[idx] = newStudentMap;
        }
      }
    });

    StudentModel studentObj = StudentModel(
      id: isEditing ? int.tryParse(_editingStudentId!) : null,
      stringId: isEditing ? _editingStudentId : null,
      name: name,
      phone: phone,
      district: district,
      neighbor: neighbor,
      className: targetClass,
      fullName: name,
    );

    bool success = false;
    if (isEditing) {
      success = await ApiService.updateStudent(_editingStudentId!, studentObj);
    } else {
      success = await ApiService.registerStudent(studentObj);
    }

    if (!mounted) return;

    _clearFields();
    if (success) {
      await _loadDataFromDatabase(); 
      if (!mounted) return;
      setState(() {
        _viewingClass = targetClass;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? "✅ Ardayga si guul leh ayaa loo cusboonaysiiyey!" : "✅ Ardayga cusub si guul leh ayaa loo diiwaangeliyey!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteStudentFromDb(String id) async {
    setState(() => _isSyncing = true);
    bool isDeleted = await ApiService.deleteStudent(id);
    if (!mounted) return;
    if (isDeleted) {
      await _loadDataFromDatabase();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Ardayga waa la tirtiray"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Tirtirku ma suurtagalin!"), backgroundColor: Colors.red),
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
    _editingStudentId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _buildFormCard(),
                ),
                Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildStudentSection(isDesktop: true),
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 16),
                  _buildStudentSection(isDesktop: false),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_editingStudentId != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Habka Wax-ka-bedelka (Edit Mode)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _clearFields()),
                      tooltip: "Ka noqo Edit",
                    ),
                  ],
                ),
              ),
            ],
            Text(
              _editingStudentId != null ? "Cusboonaysii Ardayga" : "Add New Student", 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
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
            : Column(
                children: [
                  ElevatedButton(
                    onPressed: _saveStudent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _editingStudentId == null 
                              ? [const Color(0xFF6A11CB), const Color(0xFF2575FC)]
                              : [Colors.orange.shade700, Colors.deepOrange.shade600],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        height: 55,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_editingStudentId == null ? Icons.save : Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _editingStudentId == null ? "Kaydi Xogta" : "Cusboonaysii Xogta", 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_editingStudentId != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _clearFields()),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text("Ka noqo Edit-ka", style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSection({required bool isDesktop}) {
    final listWidget = Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: _isSyncing 
        ? const Center(child: CircularProgressIndicator())
        : _viewingClass == null 
          ? const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Fadlan doorto mid ka mid ah fasallada kore"),
            ))
          : _buildFilteredStudentList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text("Dooro Fasal si aad u aragto Ardayda", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            ),
            IconButton.filled(
              onPressed: _addNewClassDialog, 
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF6A11CB)),
              tooltip: "Add New Class",
            )
          ],
        ),
        const SizedBox(height: 15),
        
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
              height: 110,
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
                      width: 100,
                      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
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
                          Icon(Icons.school, color: isSelected ? Colors.white : Colors.blueGrey, size: 24),
                          const SizedBox(height: 6),
                          Text(_classes[index], 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.white : Colors.black87)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        if (isDesktop)
          Expanded(child: listWidget)
        else
          SizedBox(height: 400, child: listWidget),
      ],
    );
  }

  Widget _buildFilteredStudentList() {
    final filteredList = students.where((s) => s['class'] == _viewingClass).toList();
    if (filteredList.isEmpty) return const Center(child: Text("Fasalkan arday kuma jirto"));

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final student = filteredList[index];
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
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _startUpdate(student)),
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

  void _startUpdate(Map<String, String> student) {
    setState(() {
      _editingStudentId = student['id'];
      _nameController.text = student['name'] ?? '';
      _phoneController.text = student['phone'] ?? '';
      _districtController.text = student['district'] ?? '';
      _neighborController.text = student['neighbor'] ?? '';
      
      String? cls = student['class'];
      if (cls != null && cls.isNotEmpty) {
        if (!_classes.contains(cls)) {
          _classes.add(cls);
        }
        _selectedClass = cls;
        _viewingClass = cls;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Waxaad wax ka bedelaysaa: ${student['name']}"),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _showStudentDetails(Map<String, String> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text(student['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            _detailRow("Fasalka:", student['class'] ?? '-'),
            _detailRow("Taleefanka:", student['phone'] ?? '-'),
            _detailRow("Degmada:", student['district'] ?? '-'),
            _detailRow("Xaafadda:", student['neighbor'] ?? '-'),
            const Divider(),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startUpdate(student);
            },
            icon: const Icon(Icons.edit, color: Colors.blue),
            label: const Text("Wax ka bedel (Edit)", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Xidh", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
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