import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class SetScheduleScreen extends StatefulWidget {
  @override
  _SetScheduleScreenState createState() => _SetScheduleScreenState();
}

class _SetScheduleScreenState extends State<SetScheduleScreen> {
  final TextEditingController topicController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController timeZoneController = TextEditingController();

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  void _selectTime(TextEditingController controller) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        controller.text = pickedTime.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TabBar
            const SizedBox(height: 20),
            // Form Fields
            CustomTextField(
              labelText: "Meeting Topic",
              controller: topicController,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              labelText: "Date",
              controller: dateController,
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: "Start from",
                    controller: startTimeController,
                    icon: Icons.access_time,
                    readOnly: true,
                    onTap: () => _selectTime(startTimeController),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    labelText: "End",
                    controller: endTimeController,
                    icon: Icons.access_time,
                    readOnly: true,
                    onTap: () => _selectTime(endTimeController),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              labelText: "Set Time Zone",
              controller: timeZoneController,
              icon: Icons.access_time,
              readOnly: true,
              onTap: () {
                // Implement time zone selection logic
              },
            ),
            const SizedBox(height: 200),
            // Submit Button
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                child: svAppButton(
                  context: context,
                  onTap: () => (),
                  text: 'SCHEDULE',
                ),
              ),
            ),
            const SizedBox(height: 30),

          ],
        ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final IconData? icon;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    Key? key,
    required this.labelText,
    required this.controller,
    this.icon,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText,style: const TextStyle(color: Colors.black,fontWeight: FontWeight.w600),),
        Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            border: Border.all(color: Colors.grey,width: 1),
            borderRadius:  BorderRadius.circular(8),
          ),
          height: 50,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(

              filled: false,
              // fillColor: Colors.grey.shade200,
              hintText: labelText,
              suffixIcon: icon != null ? Container(
                // height: 50,
                width: 70,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey,width: 0.8),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(8),bottomRight: Radius.circular(8)),
                    color: const Color(0xFFE6E6E6),

                  ),
                  child: Icon(icon)) : null,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

