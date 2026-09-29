import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/itinerary_item.dart';
import '../services/storage_service.dart';
import 'event_editor_screen.dart';

class TripManagerScreen extends StatefulWidget {
  const TripManagerScreen({Key? key}) : super(key: key);

  @override
  State<TripManagerScreen> createState() => _TripManagerScreenState();
}

class _TripManagerScreenState extends State<TripManagerScreen> {
  List<ItineraryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final list = await StorageService.getItinerary();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    await StorageService.deleteItineraryItem(id);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'TRIP MANAGER',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amberAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text('ADD EVENT', style: TextStyle(fontWeight: FontWeight.w900)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventEditorScreen()),
          );
          if (res == true) _loadItems();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No itinerary events. Tap + to add one.',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 30),
                      ),
                      onDismissed: (_) => _deleteItem(item.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Colors.amberAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${dateFormat.format(item.startTime)} - ${DateFormat('HH:mm').format(item.endTime)}",
                                    style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.localAddress,
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.cyanAccent),
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventEditorScreen(item: item),
                                ),
                              );
                              if (res == true) _loadItems();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
