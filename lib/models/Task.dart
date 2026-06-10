class Task {
  String title;
  String description; // nuevo campo para la descripción
  DateTime creationTime;
  DateTime? completionTime;
  DateTime? dueDate; // nuevo campo para la fecha de vencimiento
  bool isChecked;

  Task({
    required this.title,
    this.description = '', // valor por defecto vacío
    required this.creationTime,
    this.completionTime,
    this.dueDate, // added parameter for dueDate
    this.isChecked = false,
  });

  // Helper function to get the formatted due date.
  String getFormattedDueDate() {
    if (dueDate == null) return '';
    return "${dueDate!.day.toString().padLeft(2, '0')}/${dueDate!.month.toString().padLeft(2, '0')}/${dueDate!.year}";
  }
}
