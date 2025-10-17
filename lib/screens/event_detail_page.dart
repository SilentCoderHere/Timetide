import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'add_event_sheet.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int days;
    if (widget.event.type == 'countdown') {
      days = widget.event.eventDate.difference(now).inDays;
    } else {
      days = now.difference(widget.event.eventDate).inDays;
    }

    final bool isOverdue = (widget.event.type == 'countdown' && days < 0);
    final bool isToday = (days == 0);
    String timeText;
    Color textColor;

    if (widget.event.type == 'countdown') {
      if (isToday) {
        timeText = 'Today';
      } else if (days > 0) {
        timeText = '$days days left';
      } else {
        timeText = '${days.abs()} days ago';
      }
      textColor = isOverdue
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.onSurfaceVariant;
    } else {
      timeText = isToday ? 'Today' : '$days days ago';
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedEvent = await showModalBottomSheet<EventModel>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (BuildContext context) =>
                    AddEventSheet(event: widget.event),
              );
              if (updatedEvent != null && mounted) {
                Navigator.of(context).pop(updatedEvent);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete Event?'),
                    content: const Text(
                      'Are you sure you want to delete this event?',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text('Delete'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              ).then((confirmed) {
                if (confirmed == true && mounted) {
                  Navigator.of(context).pop('delete');
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'event-name-${widget.event.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      widget.event.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.event.description ?? 'No description',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        widget.event.type == 'countdown'
                            ? Icons.hourglass_bottom
                            : Icons.timer_outlined,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      timeText,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Event Date: ${widget.event.eventDate.toLocal().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
