import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../database/database_helper.dart';
import 'add_event_sheet.dart';
import 'event_detail_page.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<EventModel> _events = [];
  List<EventModel> _displayedEvents = [];
  bool _loading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _selectedFilterIndex = 0; // 0: All, 1: Countdown, 2: Countup
  bool _isSearching = false;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _loadEvents();
  }

  @override
  void dispose() {
    _animController.dispose();
    DatabaseHelper.instance.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final events = await DatabaseHelper.instance.getEvents();
    if (mounted) {
      setState(() {
        _events = events;
        _loading = false;
      });
      _applyFilters();
      _animController.forward();
    }
  }

  void _applyFilters() {
    List<EventModel> filtered = _selectedFilterIndex == 0
        ? _events
        : _selectedFilterIndex == 1
        ? _events.where((e) => e.type == 'countdown').toList()
        : _events.where((e) => e.type == 'countup').toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    setState(() {
      _displayedEvents = filtered
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
    });
  }

  Future<void> _addEvent(EventModel event) async {
    await DatabaseHelper.instance.insertEvent(event);
    await _loadEvents();
  }

  Future<void> _updateEvent(EventModel event) async {
    if (event.id != null) {
      await DatabaseHelper.instance.updateEvent(event);
      await _loadEvents();
    }
  }

  Future<void> _deleteEvent(int id) async {
    await DatabaseHelper.instance.deleteEvent(id);
    await _loadEvents();
  }

  Future<void> _openAddDialog() async {
    final newEvent = await showModalBottomSheet<EventModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const AddEventSheet(),
    );
    if (newEvent != null && mounted) {
      await _addEvent(newEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search events...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white60),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  _searchQuery = value;
                  _applyFilters();
                },
              )
            : const Text('Time Tide'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                  _applyFilters();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final refreshed = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              if (refreshed == true) {
                await _loadEvents();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: ToggleButtons(
                        isSelected: [
                          _selectedFilterIndex == 0,
                          _selectedFilterIndex == 1,
                          _selectedFilterIndex == 2,
                        ],
                        onPressed: (index) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                          _applyFilters();
                        },
                        borderRadius: BorderRadius.circular(12),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        borderColor: Theme.of(context).colorScheme.outline,
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.all_inclusive, size: 20),
                                SizedBox(width: 8),
                                Text('All'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.hourglass_bottom, size: 20),
                                SizedBox(width: 8),
                                Text('Countdown'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Countup'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _displayedEvents.isEmpty
                        ? AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: child,
                              );
                            },
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No events found.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            itemCount: _displayedEvents.length,
                            itemBuilder: (BuildContext context, int idx) {
                              final ev = _displayedEvents[idx];
                              return AnimatedBuilder(
                                animation: _animController,
                                builder: (context, child) {
                                  final animation =
                                      Tween<Offset>(
                                        begin: const Offset(0, 0.5),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animController,
                                          curve: Interval(
                                            (idx * 0.1),
                                            1.0,
                                            curve: Curves.easeOut,
                                          ),
                                        ),
                                      );
                                  return SlideTransition(
                                    position: animation,
                                    child: Opacity(
                                      opacity: _fadeAnimation.value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildEventTile(ev),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(opacity: _fadeAnimation.value, child: child),
          );
        },
        child: FloatingActionButton(
          onPressed: _openAddDialog,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEventTile(EventModel ev) {
    final now = DateTime.now();
    int days;
    if (ev.type == 'countdown') {
      days = ev.eventDate.difference(now).inDays;
    } else {
      days = now.difference(ev.eventDate).inDays;
    }

    final bool isOverdue = (ev.type == 'countdown' && days < 0);
    final bool isToday = (days == 0);
    String timeText;
    Color textColor;

    if (ev.type == 'countdown') {
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push<dynamic>(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => EventDetailPage(event: ev),
              ),
            );

            if (result == 'delete' && mounted) {
              await _deleteEvent(ev.id!);
            } else if (result is EventModel && mounted) {
              await _updateEvent(result);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    ev.type == 'countdown'
                        ? Icons.hourglass_bottom
                        : Icons.timer_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'event-name-${ev.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            ev.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeText,
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
