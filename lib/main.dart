import 'package:flutter/material.dart';

void main() {
  runApp(SalaryCalculatorApp());
}

class SalaryCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null && picked != _startTime && picked != _endTime) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _calculateSalary() {
    int startHour = _startTime.hour;
    int endHour = _endTime.hour;

    int totalHours = endHour - startHour;

    if (totalHours <= 8) {
      _salary = totalHours * 1000;
    } else {
      int extraHours = totalHours - 8;
      _salary = (8 * 1000) + (extraHours * 1.5 * 1000);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salary Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start Time: ${_startTime.format(context)}'),
                ElevatedButton(
                  onPressed: () => _selectTime(context, true),
                  child: Text('Select Start Time'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('End Time: ${_endTime.format(context)}'),
                ElevatedButton(
                  onPressed: () => _selectTime(context, false),
                  child: Text('Select End Time'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculateSalary,
              child: Text('Calculate Salary'),
            ),
            SizedBox(height: 20),
            Text(
              'Total Salary: $_salary',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
