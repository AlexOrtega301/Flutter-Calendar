import 'dart:convert';
import 'package:final_activity/models/Task.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension TaskSerialization on Task {
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'creationTime': creationTime.toIso8601String(),
      'completionTime': completionTime?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isChecked': isChecked,
    };
  }

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      creationTime: DateTime.parse(json['creationTime']),
      completionTime: json['completionTime'] != null ? DateTime.parse(json['completionTime']) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isChecked: json['isChecked'] ?? false,
    );
  }
}

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final List<Task> _pendingTasks = [];
  final List<Task> _completedTasks = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Predefined colors for the color cube selector.
  final List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.cyan,
    Colors.pink,
    Colors.tealAccent,
    Colors.brown,
    Colors.indigo,
    Colors.lime,
    Colors.amber,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
    const Color.fromARGB(255, 178, 34, 34),
    const Color.fromARGB(255, 240, 230, 140),
    const Color.fromARGB(147, 180, 57, 205),
  ];

  // Variable to control dark mode.
  bool _isDarkMode = false;

  // New selected date variable.
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadTasks();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    bool? theme = prefs.getBool('isDarkMode');
    if (theme != null) {
      setState(() {
        _isDarkMode = theme;
      });
    }
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  void _addTask() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _pendingTasks.add(Task(
          title: _controller.text,
          description: _descriptionController.text,
          creationTime: DateTime.now(),
          dueDate: _selectedDate,
        ));
        _controller.clear();
        _descriptionController.clear();
        _selectedDate = null;
      });
      _saveTasks();
    }
  }

  void _toggleCheckbox(Task task, bool isChecked) {
    setState(() {
      if (isChecked) {
        _pendingTasks.remove(task);
        task.completionTime = DateTime.now();
        _completedTasks.add(task);
      } else {
        _completedTasks.remove(task);
        task.completionTime = null;
        _pendingTasks.add(task);
      }
    });
    _saveTasks();
  }

  void _deleteTask(Task task) {
    setState(() {
      _pendingTasks.remove(task);
      _completedTasks.remove(task);
    });
    _saveTasks();
  }

  // Loads all image asset paths from the assets folder.
  Future<List<String>> _loadAssetImages() async {
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    // Filter assets that are images (png or jpg) and are in the assets folder.
    final imagePaths = manifestMap.keys
        .where((String key) =>
            key.startsWith('assets/') &&
            (key.endsWith('.png') || key.endsWith('.jpg')))
        .toList();
    return imagePaths;
  }

  // Opens a color selector and appends a marker tag to the description.
  void _selectColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecciona un Color'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                return GestureDetector(
                  onTap: () {
                    // Create a marker tag with the color's hex value.
                    String colorHex =
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                    final current = _descriptionController.text;
                    _descriptionController.text =
                        "$current [color:$colorHex]";
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    color: color,
                    height: 50,
                    width: 50,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Opens an image selector that loads images dynamically from the assets folder.
  void _selectImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<String>>(
          future: _loadAssetImages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                content: Text('Error loading images'),
              );
            }
            final imagePaths = snapshot.data!;
            return AlertDialog(
              title: Text('Selecciona una Imagen'),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: imagePaths.length,
                  itemBuilder: (context, index) {
                    final imagePath = imagePaths[index];
                    return GestureDetector(
                      onTap: () {
                        final current = _descriptionController.text;
                        // Append the image marker using only the filename.
                        _descriptionController.text =
                            "$current [image:${imagePath.split('/').last}]";
                        Navigator.of(context).pop();
                      },
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Opens a date picker to allow the user to select a due date.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Parses a task description for "[color:...]" and "[image:...]" markers
  /// and, if a dueDate is provided, displays a due date widget next to the text.
  Widget _buildTaskDescription(String description, DateTime? dueDate) {
    // Regular expressions to detect marker tags.
    final RegExp colorExp = RegExp(r'\[color:(#[A-Fa-f0-9]{6,8})\]');
    final RegExp imageExp = RegExp(r'\[image:([^\]]+)\]');

    String processed = description;
    Widget? colorWidget;
    Widget? imageWidget;

    final colorMatch = colorExp.firstMatch(description);
    if (colorMatch != null) {
      final colorHex = colorMatch.group(1)!;
      processed = processed.replaceAll(colorMatch.group(0)!, '');
      colorWidget = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Color(int.parse('0xFF${colorHex.substring(1)}')),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey),
        ),
      );
    }

    final imageMatch = imageExp.firstMatch(description);
    if (imageMatch != null) {
      final imageName = imageMatch.group(1)!;
      processed = processed.replaceAll(imageMatch.group(0)!, '');
      imageWidget = Image.asset(
        "assets/$imageName",
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    }

    // Build a due date widget if available.
    Widget? dueWidget;
    if (dueDate != null) {
      dueWidget = Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 16),
            SizedBox(width: 4),
            Text(
              "${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(processed.trim())),
        if (colorWidget != null) ...[
          SizedBox(width: 8),
          colorWidget,
        ],
        if (imageWidget != null) ...[
          SizedBox(width: 8),
          imageWidget,
        ],
        if (dueWidget != null) ...[
          SizedBox(width: 8),
          dueWidget,
        ],
      ],
    );
  }

  // Saves both lists of tasks using SharedPreferences.
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = jsonEncode(_pendingTasks.map((task) => task.toJson()).toList());
    final completedJson = jsonEncode(_completedTasks.map((task) => task.toJson()).toList());
    await prefs.setString('pendingTasks', pendingJson);
    await prefs.setString('completedTasks', completedJson);
  }

  // Loads tasks from SharedPreferences.
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString('pendingTasks');
    final completedJson = prefs.getString('completedTasks');
    if (pendingJson != null) {
      final List<dynamic> pendingList = jsonDecode(pendingJson);
      _pendingTasks.clear();
      _pendingTasks.addAll(pendingList.map((json) => TaskSerialization.fromJson(json)).toList());
    }
    if (completedJson != null) {
      final List<dynamic> completedList = jsonDecode(completedJson);
      _completedTasks.clear();
      _completedTasks.addAll(completedList.map((json) => TaskSerialization.fromJson(json)).toList());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
          brightness: _isDarkMode ? Brightness.dark : Brightness.light),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lista de Tareas (Microsoft To-Do pero Pirata!)'), 
          actions: [  
            IconButton(
              icon: Icon(
                  _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
                _saveTheme();
              },
            )
          ],
        ),
        body: Column(
          children: [
            // Task title input.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Agregar Tarea',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addTask,
                  ),
                ),
              ),
            ),
            // Description input.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                ),
              ),
            ),
            // Row with buttons to add a color cube, image marker, and select date.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _selectColor(context),
                    icon: Icon(Icons.color_lens),
                    label: Text('Add Color Cube'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _selectImage(context),
                    icon: Icon(Icons.image),
                    label: Text('Add Image'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: Icon(Icons.date_range),
                    label: Text('Select Date'),
                  ),
                ],
              ),
            ),
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Selected Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text(
                      'Pendientes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._pendingTasks.map((task) => ListTile(
                        title: Text(task.title),
                        subtitle: _buildTaskDescription(task.description, task.dueDate),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: task.isChecked,
                              onChanged: (value) => _toggleCheckbox(task, value ?? false),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteTask(task),
                            )
                          ],
                        ),
                      )),
                  ListTile(
                    title: Text(
                      'Completados',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._completedTasks.map((task) => ListTile(
                        title: Text(task.title),
                        subtitle: _buildTaskDescription(task.description, task.dueDate),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: true,
                              onChanged: (value) => _toggleCheckbox(task, value ?? false),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteTask(task),
                            )
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
