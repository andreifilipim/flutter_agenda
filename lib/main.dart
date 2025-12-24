import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'event.dart';
import 'student_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'), // English
        const Locale('pt', 'BR'), // Portuguese
      ],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> events = {};
  final TextEditingController _eventController = TextEditingController();
  late final ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final eventsForDay = events[day] ?? [];
    eventsForDay.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      final aTotalMinutes = a.time!.hour * 60 + a.time!.minute;
      final bTotalMinutes = b.time!.hour * 60 + b.time!.minute;
      return aTotalMinutes.compareTo(bTotalMinutes);
    });
    return eventsForDay;
  }

  void _addRecurringStudent(
      String studentName, List<int> selectedWeekdays, TimeOfDay? selectedTime) {
    setState(() {
      DateTime currentDate = DateTime.utc(2025, 1, 1);
      final endDate = DateTime.utc(2030, 12, 31);

      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        if (selectedWeekdays.contains(currentDate.weekday)) {
          final day = DateTime.utc(currentDate.year, currentDate.month, currentDate.day);
          events
              .putIfAbsent(day, () => [])
              .add(Event(studentName, time: selectedTime));
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  void _showEventOptionsDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: Text('Opções para "${event.title}"',
              textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close options
                  _showEditEventDialog(event);
                },
                child: const Text('Editar'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close options
                  _showDeleteConfirmationDialog(event);
                },
                child: const Text('Excluir'),
              ),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
              'Tem certeza que deseja remover "${event.title}" e todos os eventos recorrentes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final titleToRemove = event.title;
                  events.forEach((day, eventList) {
                    eventList.removeWhere((e) => e.title == titleToRemove);
                  });
                  events.removeWhere((day, eventList) => eventList.isEmpty);
                  _selectedEvents.value = _getEventsForDay(_selectedDay!);
                });
                Navigator.pop(context); // Close confirmation
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _showEditEventDialog(Event event) {
    final _editEventController = TextEditingController(text: event.title);
    TimeOfDay? newTime = event.time;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Evento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _editEventController,
                    decoration:
                        const InputDecoration(labelText: 'Nome do Evento'),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: newTime ?? TimeOfDay.now(),
                      );
                      setStateDialog(() {
                        newTime = picked;
                      });
                    },
                    child: Text(newTime == null
                        ? 'Selecionar Horário (Opcional)'
                        : 'Horário: ${newTime!.format(context)}'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final newTitle = _editEventController.text;
                    if (newTitle.isNotEmpty) {
                      setState(() {
                        final originalTitle = event.title;
                        events.forEach((day, eventList) {
                          final eventToUpdate = eventList
                              .where((e) => e.title == originalTitle);
                          for (var ev in eventToUpdate) {
                            ev.title = newTitle;
                            ev.time = newTime;
                          }
                        });
                        _selectedEvents.value = _getEventsForDay(_selectedDay!);
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          });
        });
  }

  Widget _buildCalendarPage() {
    return Column(children: [
      Container(
        child: TableCalendar(
            locale: "pt_BR",
            headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  final formatter = DateFormat('MMMM y', locale);
                  String formatted = formatter.format(date);
                  return formatted.capitalize();
                }),
            availableGestures: AvailableGestures.all,
            selectedDayPredicate: (day) => isSameDay(day, _focusedDay),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31)),
      ),
      const SizedBox(
        height: 8.0,
      ),
      Expanded(
        child: ValueListenableBuilder<List<Event>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(width: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                          onTap: () => _showEventOptionsDialog(event),
                          title: Text(event.time == null
                              ? event.title
                              : '${event.title} às ${event.time!.format(context)}')),
                    );
                  });
            }),
      )
    ]);
  }

  Widget _buildStudentsPage() {
    final studentNames = <String>{};
    events.values.forEach((eventList) {
      eventList.forEach((event) {
        studentNames.add(event.title);
      });
    });

    return ListView(
      children: [
        ...studentNames.map((name) => ListTile(title: Text(name))).toList(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Adicionar Aluno Recorrente'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentView(onAddStudent: _addRecurringStudent),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildCalendarPage(),
      _buildStudentsPage(),
    ];

    final List<String> _titles = ['Agenda de Treinos', 'Alunos'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: Colors.yellowAccent,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                _eventController.clear();
                showDialog(
                    context: context,
                    builder: (context) {
                      TimeOfDay? selectedTime;
                      return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setStateDialog) {
                        return AlertDialog(
                            scrollable: true,
                            title: const Text("Criar Evento",
                                textAlign: TextAlign.center),
                            content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  TextFormField(
                                    controller: _eventController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome do Evento',
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final TimeOfDay? picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) {
                                        setStateDialog(() {
                                          selectedTime = picked;
                                        });
                                      }
                                    },
                                    child: Text(selectedTime == null
                                        ? 'Selecionar Horário (Opcional)'
                                        : 'Horário: ${selectedTime!.format(context)}'),
                                  ),
                                  const SizedBox(height: 16.0),
                                  ElevatedButton(
                                    child: const Text("Confirmar"),
                                    onPressed: () {
                                      if (_eventController.text.isNotEmpty) {
                                        final eventName = _eventController.text;
                                        setState(() {
                                          final day = DateTime.utc(_selectedDay!.year,
                                              _selectedDay!.month, _selectedDay!.day);
                                          if (events[day] == null) {
                                            events[day] = [];
                                          }
                                          events[day]!.add(
                                              Event(eventName, time: selectedTime));
                                          _eventController.clear();
                                          _selectedEvents.value =
                                              _getEventsForDay(_selectedDay!);
                                        });
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                  const SizedBox(height: 8.0),
                                  ElevatedButton(
                                    child: const Text("Cancelar"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  )
                                ]));
                      });
                    });
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Alunos',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

extension CapitalizeFirstLetter on String {
  //function to capitalize first letter
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
