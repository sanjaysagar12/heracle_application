import 'package:flutter/material.dart';
import '../domain/models/session_model.dart';
import '../domain/models/add_exercise_request.dart';
import '../domain/exercise_repository_impl.dart';

class AddExerciseToSessionPage extends StatefulWidget {
  final WorkoutSession session;

  const AddExerciseToSessionPage({Key? key, required this.session}) : super(key: key);

  @override
  State<AddExerciseToSessionPage> createState() => _AddExerciseToSessionPageState();
}

class _AddExerciseToSessionPageState extends State<AddExerciseToSessionPage> {
  late final ExerciseRepositoryImpl _exerciseRepo;
  late final Future<List<Exercise>> _futureExercises;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  Exercise? _selectedExercise;
  final _orderIndexController = TextEditingController();
  final _plannedSetsController = TextEditingController();
  final _plannedRepsController = TextEditingController();
  final _plannedWeightController = TextEditingController();
  final _restSecondsController = TextEditingController();
  final _tempoController = TextEditingController();
  final _notesController = TextEditingController();

  // Set templates list
  List<SetTemplateForm> _setTemplates = [];

  @override
  void initState() {
    super.initState();
    _exerciseRepo = ExerciseRepositoryImpl();
    _futureExercises = _exerciseRepo.getExercises();
    
    // Initialize with default values
    _orderIndexController.text = (widget.session.sessionExercises.length + 1).toString();
    _plannedSetsController.text = '3';
    _plannedRepsController.text = '10';
    _plannedWeightController.text = '100';
    _restSecondsController.text = '90';
    _tempoController.text = '2-1-2';
    
    // Initialize with one set template
    _setTemplates.add(SetTemplateForm(
      setNumber: 1,
      plannedReps: 10,
      plannedWeight: 100,
      isWarmupSet: false,
      notes: '',
    ));
  }

  @override
  void dispose() {
    _orderIndexController.dispose();
    _plannedSetsController.dispose();
    _plannedRepsController.dispose();
    _plannedWeightController.dispose();
    _restSecondsController.dispose();
    _tempoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addSetTemplate() {
    setState(() {
      _setTemplates.add(SetTemplateForm(
        setNumber: _setTemplates.length + 1,
        plannedReps: 10,
        plannedWeight: 100,
        isWarmupSet: false,
        notes: '',
      ));
    });
  }

  void _removeSetTemplate(int index) {
    if (_setTemplates.length > 1) {
      setState(() {
        _setTemplates.removeAt(index);
        // Renumber the remaining sets
        for (int i = 0; i < _setTemplates.length; i++) {
          _setTemplates[i].setNumber = i + 1;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final request = AddExerciseRequest(
      exerciseId: _selectedExercise!.id,
      orderIndex: int.parse(_orderIndexController.text),
      plannedSets: int.parse(_plannedSetsController.text),
      plannedReps: int.parse(_plannedRepsController.text),
      plannedWeight: double.tryParse(_plannedWeightController.text),
      restSeconds: int.tryParse(_restSecondsController.text),
      tempo: _tempoController.text.isEmpty ? null : _tempoController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      setTemplates: _setTemplates.map((st) => SetTemplateRequest(
        setNumber: st.setNumber,
        plannedReps: st.plannedReps,
        plannedWeight: st.plannedWeight,
        isWarmupSet: st.isWarmupSet,
        notes: st.notes.isEmpty ? null : st.notes,
      )).toList(),
    );

    try {
      await _exerciseRepo.addExerciseToSession(widget.session.id, request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedExercise!.name} added to session')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add exercise: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Exercise to ${widget.session.name}'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _futureExercises,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final exercises = snapshot.data ?? <Exercise>[];
          if (exercises.isEmpty) {
            return const Center(child: Text('No exercises found.'));
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Exercise Dropdown
                DropdownButtonFormField<Exercise>(
                  decoration: const InputDecoration(
                    labelText: 'Exercise *',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedExercise,
                  items: exercises.map((exercise) {
                    return DropdownMenuItem(
                      value: exercise,
                      child: Text(exercise.name),
                    );
                  }).toList(),
                  onChanged: (Exercise? value) {
                    setState(() {
                      _selectedExercise = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select an exercise' : null,
                ),
                const SizedBox(height: 16),

                // Order Index
                TextFormField(
                  controller: _orderIndexController,
                  decoration: const InputDecoration(
                    labelText: 'Order Index *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Planned Sets
                TextFormField(
                  controller: _plannedSetsController,
                  decoration: const InputDecoration(
                    labelText: 'Planned Sets *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Planned Reps
                TextFormField(
                  controller: _plannedRepsController,
                  decoration: const InputDecoration(
                    labelText: 'Planned Reps *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Planned Weight
                TextFormField(
                  controller: _plannedWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Planned Weight',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),

                // Rest Seconds
                TextFormField(
                  controller: _restSecondsController,
                  decoration: const InputDecoration(
                    labelText: 'Rest Seconds',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Tempo
                TextFormField(
                  controller: _tempoController,
                  decoration: const InputDecoration(
                    labelText: 'Tempo (e.g., 2-1-2)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Set Templates Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Set Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _addSetTemplate,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Set Templates List
                ..._setTemplates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final setTemplate = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Set ${setTemplate.setNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (_setTemplates.length > 1)
                                IconButton(
                                  onPressed: () => _removeSetTemplate(index),
                                  icon: const Icon(Icons.delete, size: 20),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: setTemplate.plannedReps.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Reps',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setTemplate.plannedReps = int.tryParse(value) ?? setTemplate.plannedReps;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: setTemplate.plannedWeight?.toString() ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Weight',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) {
                                    setTemplate.plannedWeight = double.tryParse(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: setTemplate.isWarmupSet,
                                onChanged: (value) {
                                  setState(() {
                                    setTemplate.isWarmupSet = value ?? false;
                                  });
                                },
                              ),
                              const Text('Warmup Set'),
                            ],
                          ),
                          TextFormField(
                            initialValue: setTemplate.notes,
                            decoration: const InputDecoration(
                              labelText: 'Set Notes',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onChanged: (value) {
                              setTemplate.notes = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SetTemplateForm {
  int setNumber;
  int plannedReps;
  double? plannedWeight;
  bool isWarmupSet;
  String notes;

  SetTemplateForm({
    required this.setNumber,
    required this.plannedReps,
    this.plannedWeight,
    required this.isWarmupSet,
    required this.notes,
  });
}
