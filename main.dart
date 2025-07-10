import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  bool showTips = true;

  final Color darkGreen = const Color(0xFF1B5E20);

  void toggleTheme() => setState(() => isDarkMode = !isDarkMode);
  void toggleTips() => setState(() => showTips = !showTips);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: isDarkMode ? Colors.black : darkGreen,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? Colors.black : darkGreen,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: isDarkMode ? Colors.black : darkGreen,
          foregroundColor: Colors.white,
        ),
      ),
      home: ReminderHomePage(
        onToggleTheme: toggleTheme,
        onToggleTips: toggleTips,
        isDarkMode: isDarkMode,
        showTips: showTips,
      ),
    );
  }
}

class ReminderHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleTips;
  final bool isDarkMode;
  final bool showTips;

  const ReminderHomePage({
    super.key,
    required this.onToggleTheme,
    required this.onToggleTips,
    required this.isDarkMode,
    required this.showTips,
  });

  @override
  State<ReminderHomePage> createState() => _ReminderHomePageState();
}

class _ReminderHomePageState extends State<ReminderHomePage> {
  final List<Map<String, dynamic>> reminders = [];
  final List<String> tips = [
    'Tip: Break big tasks into smaller ones.',
    'Tip: Set a deadline and stick to it.',
    'Tip: Use the Pomodoro technique.',
    'Tip: Avoid multitasking.',
    'Tip: Reward yourself after finishing tasks.',
    'Tip: Use a timer to track focused work.',
  ];

  int currentTipIndex = 0;
  Timer? tipTimer;

  Future<void> openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open link")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (widget.showTips) {
        setState(() {
          currentTipIndex = (currentTipIndex + 1) % tips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    tipTimer?.cancel();
    super.dispose();
  }

  void _addReminderDialog() {
    String title = '';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Reminder'),
          content: StatefulBuilder(
            builder: (context, localSetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Occasion/Title'),
                    onChanged: (val) => title = val,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        localSetState(() => selectedDate = date);
                      }
                    },
                    child: Text(selectedDate == null
                        ? 'Pick Date'
                        : DateFormat('MMM d, yyyy').format(selectedDate!)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        localSetState(() => selectedTime = time);
                      }
                    },
                    child: Text(selectedTime == null
                        ? 'Pick Time'
                        : selectedTime!.format(context)),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (title.isNotEmpty &&
                    selectedDate != null &&
                    selectedTime != null) {
                  final dateTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );
                  setState(() {
                    reminders.add({'title': title, 'dateTime': dateTime});
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.school, color: Colors.black),
            ),
            const SizedBox(width: 12),
            const Text('AcadPro'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(
                  isDarkMode: widget.isDarkMode,
                  showTips: widget.showTips,
                  onToggleTheme: widget.onToggleTheme,
                  onToggleTips: widget.onToggleTips,
                )),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.showTips)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Padding(
                key: ValueKey(tips[currentTipIndex]),
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  tips[currentTipIndex],
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                ...reminders.map((r) => Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 12),
                  child: ListTile(
                    leading: const Icon(Icons.alarm, color: Colors.teal),
                    title: Text(r['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('MMM d, yyyy – hh:mm a').format(r['dateTime'])),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          reminders.remove(r);
                        });
                      },
                    ),
                  ),
                )),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('App Organizer',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => openLink('https://scholar.google.com'),
                            icon: const Icon(Icons.school),
                            label: const Text('Google Scholar'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => openLink('https://www.google.com'),
                            icon: const Icon(Icons.language),
                            label: const Text('Google'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => openLink('https://drive.google.com'),
                            icon: const Icon(Icons.cloud),
                            label: const Text('Drive'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => openLink('https://www.youtube.com'),
                            icon: const Icon(Icons.video_library),
                            label: const Text('YouTube'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final bool showTips;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleTips;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.showTips,
    required this.onToggleTheme,
    required this.onToggleTips,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (_) => onToggleTheme(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lightbulb),
            title: const Text('Show Productivity Tips'),
            value: showTips,
            onChanged: (_) => onToggleTips(),
          ),
          const Divider(),
          const ListTile(
            title: Text('About'),
            subtitle: Text('AcadPro – Mobile Version with App Organizer'),
          ),
        ],
      ),
    );
  }
}
