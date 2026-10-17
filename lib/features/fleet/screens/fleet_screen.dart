import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});
  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _fleets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFleets();
  }

  Future<void> _loadFleets() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      final fleetsRes = await _supabase
          .from('fleets')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false);
      final List<Map<String, dynamic>> fleetsWithCount = [];
      for (final fleet in fleetsRes) {
        final vehiclesRes = await _supabase
            .from('vehicles')
            .select('id, name, model, year, plates, km_actual')
            .eq('fleet_id', fleet['id']);
        fleetsWithCount.add({...fleet, 'vehicles': vehiclesRes});
      }
      setState(() => _fleets = fleetsWithCount);
    } catch (e) {
      debugPrint('Fleet error: $e');
    }
    setState(() => _loading = false);
  }

  void _showCreateFleetDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '2024');
    final countCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                    child: Text('Nueva flotilla',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary))),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close))
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre de la flotilla',
                    hintText: 'Ej: Reparto Norte'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: brandCtrl,
                    decoration: const InputDecoration(labelText: 'Marca'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: yearCtrl,
                    decoration: const InputDecoration(labelText: 'Año'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: countCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Cantidad de unidades'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Mínimo 1';
                      if (n > 50) return 'Máximo 50';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                'Se crearán las unidades con km=0. Podrás editar la matrícula de cada una después.',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    await _createFleet(
                      name: nameCtrl.text.trim(),
                      brand: brandCtrl.text.trim(),
                      model: modelCtrl.text.trim(),
                      year: int.parse(yearCtrl.text.trim()),
                      count: int.parse(countCtrl.text.trim()),
                    );
                  },
                  child: const Text('Crear flotilla',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _createFleet({
    required String name,
    required String brand,
    required String model,
    required int year,
    required int count,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id!;
      final fleetRes = await _supabase
          .from('fleets')
          .insert({'user_id': userId, 'name': name})
          .select()
          .single();
      final fleetId = fleetRes['id'];
      final vehicles = List.generate(
          count,
          (i) => {
                'user_id': userId,
                'fleet_id': fleetId,
                'name': brand,
                'model': model,
                'year': year,
                'km_actual': 0,
                'type': 'car',
              });
      await _supabase.from('vehicles').insert(vehicles);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Flotilla "$name" creada con $count unidades'),
          backgroundColor: Colors.green,
        ));
      }
      _loadFleets();
    } catch (e) {
      debugPrint('Create fleet error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showEditPlatesDialog(Map<String, dynamic> vehicle) {
    final platesCtrl =
        TextEditingController(text: vehicle['plates']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${vehicle['name']} ${vehicle['model']} ${vehicle['year']}',
            style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: platesCtrl,
          decoration: const InputDecoration(
              labelText: 'Matrícula / Placas',
              hintText: 'Ej: ABC-123-X'),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.amber),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabase
                    .from('vehicles')
                    .update({'plates': platesCtrl.text.trim()})
                    .eq('id', vehicle['id']);
                _loadFleets();
              } catch (e) {
                debugPrint('Update plates error: $e');
              }
            },
            child: const Text('Guardar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Flotilla',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          TextButton.icon(
            onPressed: _showCreateFleetDialog,
            icon: const Icon(Icons.add, color: AppTheme.amber),
            label: const Text('Nueva',
                style: TextStyle(
                    color: AppTheme.amber, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amber))
          : _fleets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            color: AppTheme.amber.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.corporate_fare_outlined,
                            size: 40, color: AppTheme.amber),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sin flotillas',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      const Text('Crea una flotilla para dar de alta\nvarios vehículos del mismo modelo',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: _showCreateFleetDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva flotilla',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _fleets.length,
                  itemBuilder: (context, i) {
                    final fleet = _fleets[i];
                    final vehicles =
                        List<Map<String, dynamic>>.from(fleet['vehicles'] ?? []);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: AppTheme.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(
                                    Icons.corporate_fare_outlined,
                                    color: AppTheme.amber),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(fleet['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppTheme.textPrimary)),
                                      Text(
                                          '${vehicles.length} unidad${vehicles.length != 1 ? 'es' : ''}',
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 13)),
                                    ]),
                              ),
                            ]),
                          ),
                          if (vehicles.isNotEmpty) ...[
                            const Divider(height: 1),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: vehicles.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 16),
                              itemBuilder: (ctx, j) {
                                final v = vehicles[j];
                                final plates = v['plates']?.toString() ?? '';
                                return ListTile(
                                  leading: const Icon(Icons.directions_car,
                                      color: AppTheme.textSecondary, size: 20),
                                  title: Text(
                                      '${v['name']} ${v['model']} ${v['year']}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textPrimary)),
                                  subtitle: Text(
                                      plates.isEmpty
                                          ? 'Sin matrícula'
                                          : plates,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: plates.isEmpty
                                              ? Colors.orange
                                              : AppTheme.textSecondary)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18,
                                        color: AppTheme.textSecondary),
                                    onPressed: () =>
                                        _showEditPlatesDialog(v),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: _fleets.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: AppTheme.amber,
              onPressed: _showCreateFleetDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
