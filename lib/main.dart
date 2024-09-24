import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(SalaryCalculatorApp());
}

class SalaryCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SalaryCalculator(),
    );
  }
}

class SalaryCalculator extends StatefulWidget {
  @override
  _SalaryCalculatorState createState() => _SalaryCalculatorState();
}

class _SalaryCalculatorState extends State<SalaryCalculator> {
  TimeOfDay _startTime = TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = TimeOfDay.now();
  double _salary = 0.0;
  Timer? _timer;
  bool _isStopped = false;
  bool _isManualEndTime = false;

  double _salaryPerHour = 1000.0; // Default salary per hour
  double _extraTimeRate = 1.5; // Extra time multiplier
  int _workHours = 8; // Default work hours

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load user settings
    _loadSalary(); // Load saved salary on app start
    _startRealTimeSalaryUpdate(); // Start real-time updates
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    if (_isStopped) {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _endTime,
      );
      if (picked != null) {
        setState(() {
          _endTime = picked;
          _calculateSalary(); // Recalculate salary after selecting end time
        });
      }
    }
  }

  // Calculate salary based on the selected times and user settings
  void _calculateSalary() {
    int startHour = _startTime.hour;
    int endHour = _endTime.hour;

    int totalHours = endHour - startHour;

    if (totalHours <= _workHours) {
      _salary = totalHours * _salaryPerHour;
    } else {
      int extraHours = totalHours - _workHours;
      _salary = (_workHours * _salaryPerHour) + (extraHours * _extraTimeRate * _salaryPerHour);
    }

    _saveSalary(); // Save salary to local storage
    setState(() {});
  }

  // Save salary data to local storage
  Future<void> _saveSalary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_salary', _salary);
  }

  // Load salary data from local storage
  Future<void> _loadSalary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _salary = prefs.getDouble('daily_salary') ?? 0.0;
    });
  }

  // Load user settings from local storage
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _salaryPerHour = prefs.getDouble('salary_per_hour') ?? 1000.0;
      _extraTimeRate = prefs.getDouble('extra_time_rate') ?? 1.5;
      _workHours = prefs.getInt('work_hours') ?? 8;
      int startHour = prefs.getInt('start_hour') ?? 7;
      int startMinute = prefs.getInt('start_minute') ?? 0;
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
    });
  }

  // Save user settings to local storage
  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('salary_per_hour', _salaryPerHour);
    await prefs.setDouble('extra_time_rate', _extraTimeRate);
    await prefs.setInt('work_hours', _workHours);
    await prefs.setInt('start_hour', _startTime.hour);
    await prefs.setInt('start_minute', _startTime.minute);
  }

  // Start a timer to update the salary and end time every second
  void _startRealTimeSalaryUpdate() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (!_isStopped) {
        _endTime = TimeOfDay.now(); // Update the end time to the current time
        _calculateSalary(); // Recalculate salary every second
      }
    });
  }

  // Stop real-time updates and enable manual end time selection
  void _stopRealTimeUpdates() {
    setState(() {
      _isStopped = true;
      _timer?.cancel(); // Stop the timer when clocking out
      _isManualEndTime = true; // Enable manual end time selection
    });
  }

  // Navigate to the settings page
  void _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage(
        salaryPerHour: _salaryPerHour,
        workHours: _workHours,
        extraTimeRate: _extraTimeRate,
        startTime: _startTime,
      )),
    );
    if (result != null) {
      setState(() {
        _salaryPerHour = result['salaryPerHour'];
        _workHours = result['workHours'];
        _extraTimeRate = result['extraTimeRate'];
        _startTime = result['startTime'];
        _saveSettings(); // Save settings after editing
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Salary Calculator', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _navigateToSettings, // Navigate to settings
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildTimePicker(
              context: context,
              label: 'Start Time',
              time: _startTime.format(context),
              onPressed: () => _selectStartTime(context),
            ),
            SizedBox(height: 20),
            _buildEndTimePicker(), // Display real-time or manual end time selection
            SizedBox(height: 30),
            _buildSalaryDisplay(),
            SizedBox(height: 20),
            _buildStopButton(), // Add a stop button to clock out
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required BuildContext context,
    required String label,
    required String time,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: $time',
          style: TextStyle(fontSize: 18),
        ),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Select Start Time'),
        ),
      ],
    );
  }

  Widget _buildEndTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'End Time: ${_endTime.format(context)}',
          style: TextStyle(fontSize: 18),
        ),
        ElevatedButton(
          onPressed: _isStopped ? () => _selectEndTime(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isStopped ? Colors.blueAccent : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(_isStopped ? 'Select End Time' : 'Real Time'),
        ),
      ],
    );
  }

  Widget _buildSalaryDisplay() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Current Salary: ${_salary.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return ElevatedButton(
      onPressed: _stopRealTimeUpdates,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text('Stop & Clock Out', style: TextStyle(fontSize: 18)),
    );
  }
}

// Settings page where users can adjust their preferences including start time
class SettingsPage extends StatefulWidget {
  final double salaryPerHour;
  final int workHours;
  final double extraTimeRate;
  final TimeOfDay startTime;

  const SettingsPage({
    Key? key,
    required this.salaryPerHour,
    required this.workHours,
    required this.extraTimeRate,
    required this.startTime,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _salaryPerHour;
  late int _workHours;
  late double _extraTimeRate;
  late TimeOfDay _startTime;

  @override
  void initState() {
    super.initState();
    _salaryPerHour = widget.salaryPerHour;
    _workHours = widget.workHours;
    _extraTimeRate = widget.extraTimeRate;
    _startTime = widget.startTime;
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildNumberInput(
              label: 'Salary Per Hour',
              value: _salaryPerHour.toString(),
              onChanged: (value) => _salaryPerHour = double.tryParse(value) ?? _salaryPerHour,
            ),
            SizedBox(height: 20),
            _buildNumberInput(
              label: 'Work Hours',
              value: _workHours.toString(),
              onChanged: (value) => _workHours = int.tryParse(value) ?? _workHours,
            ),
            SizedBox(height: 20),
            _buildNumberInput(
              label: 'Extra Time Rate',
              value: _extraTimeRate.toString(),
              onChanged: (value) => _extraTimeRate = double.tryParse(value) ?? _extraTimeRate,
            ),
            SizedBox(height: 20),
            _buildTimePicker(
              label: 'Start Time',
              time: _startTime.format(context),
              onPressed: () => _selectStartTime(context),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'salaryPerHour': _salaryPerHour,
                  'workHours': _workHours,
                  'extraTimeRate': _extraTimeRate,
                  'startTime': _startTime,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Save Settings', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String time,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: $time',
          style: TextStyle(fontSize: 18),
        ),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Select Time'),
        ),
      ],
    );
  }
}
