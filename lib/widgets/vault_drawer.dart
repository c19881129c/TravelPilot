import 'package:flutter/material.dart';
import '../models/vault_item.dart';
import '../services/storage_service.dart';

class VaultDrawer extends StatefulWidget {
  const VaultDrawer({Key? key}) : super(key: key);

  @override
  State<VaultDrawer> createState() => _VaultDrawerState();
}

class _VaultDrawerState extends State<VaultDrawer> {
  List<VaultItem> _vaultItems = [];

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    final items = await StorageService.getVaultItems();
    if (mounted) {
      setState(() => _vaultItems = items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF1E293B),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 32),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESSENTIAL VAULT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Offline Emergency & Bookings',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _vaultItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _vaultItems[index];
                  IconData icon;
                  Color iconColor;
                  switch (item.category) {
                    case 'Flight':
                      icon = Icons.flight_takeoff_rounded;
                      iconColor = Colors.cyanAccent;
                      break;
                    case 'Hotel':
                      icon = Icons.hotel_rounded;
                      iconColor = Colors.greenAccent;
                      break;
                    case 'Emergency':
                      icon = Icons.emergency_rounded;
                      iconColor = Colors.redAccent;
                      break;
                    default:
                      icon = Icons.info_outline_rounded;
                      iconColor = Colors.amberAccent;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: iconColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              item.title.toUpperCase(),
                              style: TextStyle(
                                color: iconColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          item.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
