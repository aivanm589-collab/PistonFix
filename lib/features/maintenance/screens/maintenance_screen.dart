import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;

  final List<Map<String, String>> _serviceTypes = [
    {'key': 'aceite', 'label': 'Cambio de aceite', 'icon': 'oil'},
    {'key': 'frenos', 'label': 'Frenos', 'icon': 'brake'},
    {'key': 'llantas', 'label': 'Llantas', 'icon': 'tire'},
    {'key': 'bateria', 'label': 'Batería', 'icon': 'battery'},
    {'key': 'filtro_aire', 'label': 'Filtro de aire', 'icon': 'filter'},
    {'key': 'bujias', 'label': 'Bujías', 'icon': 'spark'},
    {'key': 'transmision', 'label': 'Transmisión', 'icon': 'gear'},
    {'key': 'suspension', 'label': 'Suspensión', 'icon': 'shock'},
    {'key': 'aire_ac', 'label': 'Aire / A/C', 'icon': 'ac'},
    {'key': 'electrico', 'label': 'Eléctrico', 'icon': 'electric'},
    {'key': 'carroceria', 'label': 'Carrocería', 'icon': 'body'},
    {'key': 'otro', 'label': 'Otro', 'icon': 'other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      debugPrint('USER ID: $userId');
      final vehiclesRes = await _supabase
          .from('vehicles')
          .select()
          .eq('user_id', userId!);
      debugPrint('Vehicles count: ${vehiclesRes.length}');
      setState(() {
        _vehicles = List<Map<String, dynamic>>.from(vehiclesRes);
      });
    } catch (e) {
      debugPrint('VEHICLES ERROR: $e');
    }
    try {
      final userId = _supabase.auth.currentUser?.id;
      final recordsRes = await _supabase
          .from('maintenance_records')
          .select('*, vehicles(id, name, model, year, plates)')
          .eq('user_id', userId!)
          .order('date', ascending: false);
      setState(() {
        _records = List<Map<String, dynamic>>.from(recordsRes);
      });
    } catch (e) {
      debugPrint('RECORDS ERROR: $e');
    }
    setState(() => _loading = false);
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'aceite': return Icons.water_drop_outlined;
      case 'frenos': return Icons.disc_full_outlined;
      case 'llantas': return Icons.tire_repair_outlined;
      case 'bateria': return Icons.battery_charging_full_outlined;
      case 'filtro_aire': return Icons.air_outlined;
      case 'bujias': return Icons.electric_bolt_outlined;
      case 'transmision': return Icons.settings_outlined;
      case 'suspension': return Icons.directions_car_outlined;
      case 'aire_ac': return Icons.ac_unit_outlined;
      case 'electrico': return Icons.electrical_services_outlined;
      case 'carroceria': return Icons.car_repair_outlined;
      default: return Icons.build_outlined;
    }
  }

  void _showAddDialog() {
    if (_vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega un vehículo primero')),
      );
      return;
    }

    String? selectedVehicleId = _vehicles.first['id'];
    String selectedType = 'aceite';
    final descCtrl = TextEditingController();
    final costPartsCtrl = TextEditingController();
    final costLaborCtrl = TextEditingController();
    final kmCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text('Nuevo servicio',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehículo
                      const Text('Vehículo',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedVehicleId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: _vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v['id'] as String,
                            child: Text(
                                '${v['year']} ${v['name']} ${v['model']}',
                                overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setModal(() => selectedVehicleId = val),
                      ),
                      const SizedBox(height: 16),

                      // Tipo de servicio
                      const Text('Tipo de servicio',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _serviceTypes.map((s) {
                          final selected = selectedType == s['key'];
                          return GestureDetector(
                            onTap: () => setModal(() => selectedType = s['key']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.amber
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.amber
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                s['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Descripción
                      const Text('Descripción (opcional)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ej: Cambio de aceite 5W30 sintético',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Costos
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Costo refacciones',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: costPartsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    prefixText: '\$ ',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mano de obra',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: costLaborCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    prefixText: '\$ ',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Kilómetros y fecha
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kilómetros',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: kmCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    suffixText: 'km',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fecha',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: ctx,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (d != null) setModal(() => selectedDate = d);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            try {
                              final userId = _supabase.auth.currentUser?.id; print("USER ID: $userId");
                              final parts =
                                  double.tryParse(costPartsCtrl.text) ?? 0;
                              final labor =
                                  double.tryParse(costLaborCtrl.text) ?? 0;
                              await _supabase
                                  .from('maintenance_records')
                                  .insert({
                                'user_id': userId,
                                'vehicle_id': selectedVehicleId,
                                'category': selectedType,
                                'description': descCtrl.text.isEmpty
                                    ? null
                                    : descCtrl.text,
                                'part_cost': parts,
                                'labor_cost': labor,
                                'total_cost': parts + labor,
                                'km': int.tryParse(kmCtrl.text) ?? 0,
                                'date': selectedDate.toIso8601String(),
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadData();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Guardar servicio',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Mantenimiento'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add, color: AppTheme.amber),
                label: const Text('Nuevo',
                    style: TextStyle(color: AppTheme.amber)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.amber))
          : _records.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: _records.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: AppTheme.amber,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.build_outlined,
                size: 56, color: AppTheme.amber),
          ),
          const SizedBox(height: 20),
          const Text('Sin registros de servicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Registra el primer mantenimiento\nde tu vehículo',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('Registrar servicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.amber,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.amber,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (ctx, i) {
          final r = _records[i];
          final vehicle = r['vehicles'] as Map<String, dynamic>?;
          final total = (r['total_cost'] ?? 0).toDouble();
          final date = r['date'] != null
              ? DateTime.parse(r['date'])
              : DateTime.now();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconForType(r['category']),
                        color: AppTheme.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _serviceTypes.firstWhere(
                            (s) => s['key'] == r['category'],
                            orElse: () => {'label': r['category'] ?? 'Servicio'},
                          )['label']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (vehicle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle['year']} ${vehicle['name']} ${vehicle['model']}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}/${date.month}/${date.year}${r['km'] != null && r['km'] != 0 ? ' · ${r['km']} km' : ''}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.amber),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
