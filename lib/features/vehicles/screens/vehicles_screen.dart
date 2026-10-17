import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});
  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    final data = await _sb.from('vehicles').select().eq('user_id', uid).order('created_at');
    if (mounted) setState(() { _vehicles = List<Map<String,dynamic>>.from(data); _loading = false; });
  }

  IconData _vehicleIcon(String? type) {
    switch (type) {
      case 'moto': return Icons.two_wheeler;
      case 'camion': return Icons.local_shipping;
      case 'montacargas': return Icons.forklift;
      default: return Icons.directions_car;
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final kmCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    String selectedType = 'auto';
    final types = ['auto','moto','camion','camioneta','pickup','autobus','montacargas'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Nuevo vehiculo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setModal(() => selectedType = v!),
              ),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre / Alias')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Marca'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Modelo'))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ano'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: kmCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Km actuales'))),
              ]),
              const SizedBox(height: 8),
              TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'Placas')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final uid = _sb.auth.currentUser?.id;
                  if (uid == null) return;
                  await _sb.from('vehicles').insert({
                    'user_id': uid,
                    'name': nameCtrl.text.trim(),
                    'brand': brandCtrl.text.trim(),
                    'model': modelCtrl.text.trim(),
                    'year': int.tryParse(yearCtrl.text) ?? 0,
                    'current_km': int.tryParse(kmCtrl.text) ?? 0,
                    'plate': plateCtrl.text.trim(),
                    'type': selectedType,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                child: const Text('Guardar vehiculo'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Vehiculos')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.amber,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.amber))
        : _vehicles.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.directions_car_outlined, size: 64, color: AppTheme.textSecondary),
              SizedBox(height: 12),
              Text('Sin vehiculos aun', style: TextStyle(color: AppTheme.textSecondary)),
            ]))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final v = _vehicles[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.amber.withOpacity(0.15),
                        child: Icon(_vehicleIcon(v['type']), color: AppTheme.amber)),
                      title: Text(v['name'] ?? '${v['brand']} ${v['model']}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${v['brand'] ?? ''} ${v['model'] ?? ''} ${v['year'] ?? ''} - ${v['current_km'] ?? 0} km'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
