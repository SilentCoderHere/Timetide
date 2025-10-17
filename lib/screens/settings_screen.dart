import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/event_model.dart';
import '../database/database_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<List<EventModel>> _getAllEvents() async {
    return await DatabaseHelper.instance.getEvents();
  }

  Future<void> _backupToJson(BuildContext context) async {
    try {
      final allEvents = await _getAllEvents();
      final jsonData = jsonEncode(
        allEvents.map((e) => e.toMap()..remove('id')).toList(),
      ); // remove id for portability

      final tempDir = await getTemporaryDirectory();
      final backupFile = File(
        '${tempDir.path}/events_backup_${DateTime.now().toIso8601String()}.json',
      );
      await backupFile.writeAsString(jsonData);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(backupFile.path)], text: 'Events Backup'),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup shared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _restoreFromJson(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final events = jsonList.map((map) => EventModel.fromMap(map)).toList();

      final db = DatabaseHelper.instance;
      await db.database; // ensure DB is initialized
      // Clear existing events before restoring
      final existingEvents = await db.getEvents();
      for (var ev in existingEvents) {
        await db.deleteEvent(ev.id!);
      }
      for (var ev in events) {
        await db.insertEvent(ev);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Restore successful.')));

      Navigator.pop(context, true); // trigger refresh
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Events'),
        content: const Text(
          'This will delete all events permanently. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = DatabaseHelper.instance;
        final allEvents = await db.getEvents();
        for (var ev in allEvents) {
          await db.deleteEvent(ev.id!);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All events cleared')));
        Navigator.pop(context, true); // trigger refresh
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Clear failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup to JSON'),
            subtitle: const Text(
              'Export all events as a JSON file and share it',
            ),
            onTap: () => _backupToJson(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from JSON'),
            subtitle: const Text(
              'Import events from a JSON backup file (overwrites existing data)',
            ),
            onTap: () => _restoreFromJson(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear All Events'),
            subtitle: const Text('Permanently delete all events'),
            onTap: () => _clearAllData(context),
          ),
        ],
      ),
    );
  }
}
