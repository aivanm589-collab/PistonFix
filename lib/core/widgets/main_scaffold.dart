import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/vehicles')) return 1;
    if (location.startsWith('/maintenance')) return 2;
    if (location.startsWith('/fleet')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),
        onTap: (i) {
          switch (i) {
            case 0: context.go('/dashboard');
            case 1: context.go('/vehicles');
            case 2: context.go('/maintenance');
            case 3: context.go('/fleet');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), activeIcon: Icon(Icons.directions_car), label: 'Vehiculos'),
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), activeIcon: Icon(Icons.build), label: 'Servicio'),
          BottomNavigationBarItem(icon: Icon(Icons.corporate_fare_outlined), activeIcon: Icon(Icons.corporate_fare), label: 'Flotilla'),
        ],
      ),
    );
  }
}
