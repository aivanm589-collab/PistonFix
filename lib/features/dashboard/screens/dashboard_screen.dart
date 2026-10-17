import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _sb = Supabase.instance.client;
  int _totalVehicles = 0;
  int _pendingServices = 0;
  double _totalCost = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final vehicles = await _sb.from('vehicles').select('id').eq('user_id', uid);
      final maintenance = await _sb.from('maintenance_records').select('cost_parts, cost_labor, next_km, next_date').eq('user_id', uid);
      double total = 0;
      int pending = 0;
      for (final r in maintenance) {
        total += ((r['cost_parts'] ?? 0) as num).toDouble();
        total += ((r['cost_labor'] ?? 0) as num).toDouble();
        final nextKm = r['next_km'] as int?;
        if (nextKm != null && nextKm > 0) pending++;
      }
      if (mounted) setState(() {
        _totalVehicles = vehicles.length;
        _pendingServices = pending;
        _totalCost = total;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PistonFix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _sb.auth.signOut(),
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.amber))
        : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Resumen', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _KpiCard(label: 'Vehículos', value: '$_totalVehicles', icon: Icons.directions_car)),
                  const SizedBox(width: 12),
                  Expanded(child: _KpiCard(label: 'Servicios pendientes', value: '$_pendingServices', icon: Icons.build, color: _pendingServices > 0 ? Colors.orange : AppTheme.amber)),
                ]),
                const SizedBox(height: 12),
                _KpiCard(label: 'Costo total acumulado', value: '\$${_totalCost.toStringAsFixed(0)} MXN', icon: Icons.attach_money, wide: true),
                const SizedBox(height: 24),
                Text('Accesos rápidos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _QuickAction(icon: Icons.add_circle_outline, label: 'Nuevo vehículo', onTap: () => context.go('/vehicles'))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.build_circle_outlined, label: 'Registrar servicio', onTap: () => context.go('/maintenance'))),
                ]),
              ],
            ),
          ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? color;
  final bool wide;
  const _KpiCard({required this.label, required this.value, required this.icon, this.color, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.amber, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.amber, size: 32),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
