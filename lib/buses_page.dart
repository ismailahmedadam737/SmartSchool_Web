import 'package:flutter/material.dart';
import 'package:iftiinshe/Service/api_service.dart';
import '../models/bus_model.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key});

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();

  List<Bus> busList = [];
  bool _isLoading = true;
  int? _editingBusId;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getAllBuses();
    setState(() {
      busList = data;
      _isLoading = false;
    });
  }

  Future<void> _saveOrUpdateBus() async {
    if (_nameController.text.isEmpty || _plateController.text.isEmpty) return;

    final busData = Bus(
      id: _editingBusId,
      name: _nameController.text,
      phone: _phoneController.text,
      plate: _plateController.text,
      route: _routeController.text,
    );

    bool success;
    if (_editingBusId == null) {
      success = await ApiService.registerBus(busData);
    } else {
      success = await ApiService.updateBus(_editingBusId!, busData);
    }

    if (success) {
      _loadBuses();
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Si guul leh ayaa loo keydiyey")),
      );
    }
  }

  Future<void> _deleteBus(int id) async {
    bool confirm = await _showConfirmDialog();
    if (confirm) {
      final success = await ApiService.deleteBus(id);
      if (success) {
        _loadBuses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Baska waa la tirtiray")),
        );
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _plateController.clear();
    _routeController.clear();
    setState(() => _editingBusId = null);
  }

  void _editBus(Bus bus) {
    setState(() {
      _editingBusId = bus.id;
      _nameController.text = bus.name;
      _phoneController.text = bus.phone;
      _plateController.text = bus.plate;
      _routeController.text = bus.route;
    });
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ma hubtaa?"),
        content: const Text("Xogtan dib looma soo celin karo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Maya")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Haa", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Maareynta Basaska Dugsiga", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: _buildAddBusForm()),
            const SizedBox(width: 30),
            Expanded(
              flex: 6, 
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _buildBusList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddBusForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_editingBusId == null ? "Diiwaangeli Bas Cusub" : "Wax ka beddel Baska", 
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField("Magaca Dirawalka", Icons.person, _nameController),
          _buildTextField("Taleefanka", Icons.phone, _phoneController),
          _buildTextField("Taarikada Gaadhiga", Icons.directions_bus, _plateController),
          _buildTextField("Wadada uu Maro", Icons.map, _routeController),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_editingBusId != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
              if (_editingBusId != null) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _editingBusId == null ? const Color(0xFF6A11CB) : Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: _saveOrUpdateBus,
                  child: Text(_editingBusId == null ? "Save Bus Info" : "Update Bus", 
                         style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Basaska Diiwaangashan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        busList.isEmpty 
          ? const Center(child: Text("Ma jiraan basas diiwaangashan"))
          : ListView.builder(
              shrinkWrap: true,
              itemCount: busList.length,
              itemBuilder: (context, index) {
                var bus = busList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      // Magaca oo Popup-ka kicinaya marka la riixo
                      Expanded(
                        child: InkWell(
                          onTap: () => _showBusDetails(bus),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              bus.name, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ),
                        ),
                      ),
                      // Actions xaga dambe
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.blue),
                        onPressed: () => _editBus(bus),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteBus(bus.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }

  void _showBusDetails(Bus bus) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF6A11CB),
                  child: Icon(Icons.directions_bus, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(bus.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Divider(height: 30),
                _buildPopupInfo(Icons.phone, "Taleefanka", bus.phone),
                _buildPopupInfo(Icons.confirmation_number, "Taarikada", bus.plate),
                _buildPopupInfo(Icons.location_on, "Wadada", bus.route),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Xidh", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildPopupInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 20),
          const SizedBox(width: 15),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}