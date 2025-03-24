import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/pet_model.dart';
import 'models/appointment_model.dart';
import 'models/reminder_model.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(PetAdapter());
  Hive.registerAdapter(AppointmentAdapter());
  Hive.registerAdapter(ReminderAdapter());

  // Open Hive boxes
  await Hive.openBox<Pet>('pets');
  await Hive.openBox<Appointment>('appointments');
  await Hive.openBox<Reminder>('reminders');

  runApp(const PetCareApp());
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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

  final List<Widget> _pages = [
    const PetProfilesPage(),
    const AppointmentsPage(),
    const RemindersPage(),
    const TrainingAndDietPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Pets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Training & Diet',
          ),
        ],
      ),
    );
  }
}

// Pet Profiles Page
class PetProfilesPage extends StatelessWidget {
  const PetProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Pet>('pets').listenable(),
        builder: (context, Box<Pet> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No pets added yet'),
                  ElevatedButton(
                    onPressed: () => _showAddPetDialog(context),
                    child: const Text('Add Pet'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final pet = box.getAt(index);
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(pet!.name.isNotEmpty ? pet.name[0] : '?'),
                  ),
                  title: Text(pet.name),
                  subtitle: Text('${pet.species} - ${pet.breed}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddPetDialog(context, pet: pet),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deletePet(context, pet),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPetDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deletePet(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to delete ${pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              pet.delete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddPetDialog(BuildContext context, {Pet? pet}) {
    showDialog(
      context: context,
      builder: (context) => AddPetDialog(pet: pet),
    );
  }
}

class AddPetDialog extends StatefulWidget {
  final Pet? pet;

  const AddPetDialog({super.key, this.pet});

  @override
  State<AddPetDialog> createState() => _AddPetDialogState();
}

class _AddPetDialogState extends State<AddPetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _breedController;
  late DateTime _birthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet?.name);
    _speciesController = TextEditingController(text: widget.pet?.species);
    _breedController = TextEditingController(text: widget.pet?.breed);
    _birthDate = widget.pet?.birthDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.pet == null ? 'Add New Pet' : 'Edit Pet'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Pet Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(labelText: 'Species'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter species' : null,
              ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter breed' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePet,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _savePet() {
    if (_formKey.currentState?.validate() ?? false) {
      final petsBox = Hive.box<Pet>('pets');
      final pet = Pet(
        name: _nameController.text,
        species: _speciesController.text,
        breed: _breedController.text,
        birthDate: _birthDate,
      );

      if (widget.pet != null) {
        widget.pet!.name = pet.name;
        widget.pet!.species = pet.species;
        widget.pet!.breed = pet.breed;
        widget.pet!.birthDate = pet.birthDate;
        widget.pet!.save();
      } else {
        petsBox.add(pet);
      }

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    super.dispose();
  }
}

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Appointment>('appointments').listenable(),
        builder: (context, Box<Appointment> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No appointments scheduled'),
                  ElevatedButton(
                    onPressed: () => _showAddAppointmentDialog(context),
                    child: const Text('Schedule Appointment'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final appointment = box.getAt(index);
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.calendar_today),
                  ),
                  title: Text('Appointment with ${appointment!.vetName}'),
                  subtitle: Text(
                    'Date: ${appointment.dateTime.toString().split(' ')[0]}\n'
                    'Time: ${appointment.dateTime.toString().split(' ')[1]}\n'
                    'Reason: ${appointment.reason}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteAppointment(context, appointment),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAppointmentDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAppointmentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final vetNameController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Appointment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: vetNameController,
                  decoration: const InputDecoration(labelText: 'Vet Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter vet name' : null,
                ),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter reason' : null,
                ),
                ListTile(
                  title: const Text('Select Date'),
                  subtitle: Text(selectedDate.toString().split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      selectedDate = date;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final appointment = Appointment(
                  petId: '1', // TODO: Get selected pet ID
                  dateTime: selectedDate,
                  reason: reasonController.text,
                  vetName: vetNameController.text,
                );
                Hive.box<Appointment>('appointments').add(appointment);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteAppointment(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appointment.delete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Reminder>('reminders').listenable(),
        builder: (context, Box<Reminder> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No reminders set'),
                  ElevatedButton(
                    onPressed: () => _showAddReminderDialog(context),
                    child: const Text('Add Reminder'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final reminder = box.getAt(index);
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: reminder!.isCompleted ? Colors.green : Colors.orange,
                    child: Icon(
                      reminder.isCompleted ? Icons.check : Icons.notifications,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(reminder.title),
                  subtitle: Text(
                    '${reminder.description}\n'
                    'Due: ${reminder.dateTime.toString().split(' ')[0]}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          reminder.isCompleted ? Icons.undo : Icons.check,
                          color: reminder.isCompleted ? Colors.orange : Colors.green,
                        ),
                        onPressed: () => _toggleReminder(reminder),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteReminder(context, reminder),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reminder'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a description' : null,
                ),
                ListTile(
                  title: const Text('Select Date'),
                  subtitle: Text(selectedDate.toString().split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      selectedDate = date;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final reminder = Reminder(
                  petId: '1', // TODO: Get selected pet ID
                  title: titleController.text,
                  description: descriptionController.text,
                  dateTime: selectedDate,
                );
                Hive.box<Reminder>('reminders').add(reminder);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleReminder(Reminder reminder) {
    reminder.isCompleted = !reminder.isCompleted;
    reminder.save();
  }

  void _deleteReminder(BuildContext context, Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              reminder.delete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class TrainingAndDietPage extends StatelessWidget {
  const TrainingAndDietPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Training Tips'),
              subtitle: const Text('View and manage pet training tips'),
              onTap: () => _showTrainingTips(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Diet Plans'),
              subtitle: const Text('View and manage pet diet plans'),
              onTap: () => _showDietPlans(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrainingTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Training Tips'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrainingTip(
                'Basic Commands',
                'Start with sit, stay, and come commands. Use positive reinforcement.',
              ),
              _buildTrainingTip(
                'House Training',
                'Establish a routine for potty breaks and reward good behavior.',
              ),
              _buildTrainingTip(
                'Socialization',
                'Expose your pet to different environments and other animals.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDietPlans(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diet Plans'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDietTip(
                'Regular Feeding Schedule',
                'Feed your pet at the same times each day.',
              ),
              _buildDietTip(
                'Portion Control',
                'Follow recommended portion sizes based on age and weight.',
              ),
              _buildDietTip(
                'Fresh Water',
                'Ensure clean, fresh water is always available.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingTip(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildDietTip(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}
