import "package:flutter/material.dart";

class StudentView extends StatefulWidget {
  final Function(String, List<int>, TimeOfDay?) onAddStudent;

  const StudentView({Key? key, required this.onAddStudent}) : super(key: key);

  @override
  _StudentViewState createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> {
  final _studentNameController = TextEditingController();
  final List<String> daysOfWeek = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
  final Map<String, bool> _selectedDays = {
    'Seg': false, 'Ter': false, 'Qua': false, 'Qui': false, 'Sex': false, 'Sab': false, 'Dom': false
  };
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _studentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Aluno Recorrente'),
        centerTitle: true,
        backgroundColor: Colors.yellowAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _studentNameController,
              decoration: const InputDecoration(labelText: 'Nome do Aluno'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedTime = picked;
                  });
                }
              },
              child: Text(_selectedTime == null
                  ? 'Selecionar Horário'
                  : 'Horário: ${_selectedTime!.format(context)}'),
            ),
            const SizedBox(height: 16.0),
            const Text("Selecione os dias da semana:", textAlign: TextAlign.left),
            Wrap(
              spacing: 4.0,
              runSpacing: -8.0,
              children: daysOfWeek.map((day) {
                return FilterChip(
                  label: Text(day, style: const TextStyle(fontSize: 12)),
                  selected: _selectedDays[day]!,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedDays[day] = selected;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              child: const Text("Confirmar"),
              onPressed: () {
                final studentName = _studentNameController.text;
                if (studentName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, insira o nome do aluno.')));
                  return;
                }

                final Map<String, int> dayNameToWeekday = {
                  'Seg': DateTime.monday,
                  'Ter': DateTime.tuesday,
                  'Qua': DateTime.wednesday,
                  'Qui': DateTime.thursday,
                  'Sex': DateTime.friday,
                  'Sab': DateTime.saturday,
                  'Dom': DateTime.sunday,
                };

                final List<int> selectedWeekdays = [];
                _selectedDays.forEach((day, isSelected) {
                  if (isSelected) {
                    selectedWeekdays.add(dayNameToWeekday[day]!);
                  }
                });

                if (selectedWeekdays.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, selecione pelo menos um dia da semana.')));
                  return;
                }

                widget.onAddStudent(studentName, selectedWeekdays, _selectedTime);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ), 
      ),
    );
  }
}
