import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/itinerary_item.dart';
import '../services/storage_service.dart';

class EventEditorScreen extends StatefulWidget {
  final ItineraryItem? item;

  const EventEditorScreen({Key? key, this.item}) : super(key: key);

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _bookingRefCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;

  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _addressCtrl = TextEditingController(text: item?.localAddress ?? '');
    _bookingRefCtrl = TextEditingController(text: item?.bookingRef ?? '');
    _notesCtrl = TextEditingController(text: item?.notes ?? '');
    _latCtrl = TextEditingController(text: item != null ? item.lat.toString() : '43.0605');
    _lngCtrl = TextEditingController(text: item != null ? item.lng.toString() : '141.3564');

    _startTime = item?.startTime ?? DateTime.now().add(const Duration(hours: 1));
    _endTime = item?.endTime ?? DateTime.now().add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _bookingRefCtrl.dispose();
    _notesCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.amberAccent,
            onPrimary: Colors.black,
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.amberAccent,
            onPrimary: Colors.black,
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = picked;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newItem = ItineraryItem(
      id: widget.item?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
      lat: double.tryParse(_latCtrl.text.trim()) ?? 43.0605,
      lng: double.tryParse(_lngCtrl.text.trim()) ?? 141.3564,
      localAddress: _addressCtrl.text.trim(),
      bookingRef: _bookingRefCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    if (widget.item == null) {
      await StorageService.addItineraryItem(newItem);
    } else {
      await StorageService.updateItineraryItem(newItem);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          widget.item == null ? 'ADD EVENT' : 'EDIT EVENT',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.amberAccent, size: 28),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Event Title', _titleCtrl, isRequired: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerCard(
                      'START TIME',
                      dateFormat.format(_startTime),
                      () => _pickDateTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimePickerCard(
                      'END TIME',
                      dateFormat.format(_endTime),
                      () => _pickDateTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Latitude', _latCtrl, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Longitude', _lngCtrl, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Local Address (Taxi / Kanji)', _addressCtrl),
              const SizedBox(height: 16),
              _buildTextField('Booking Reference', _bookingRefCtrl),
              const SizedBox(height: 16),
              _buildTextField('Notes & Instructions', _notesCtrl, maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _save,
                  child: const Text(
                    'SAVE ITINERARY EVENT',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      validator: isRequired ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amberAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildTimePickerCard(String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
