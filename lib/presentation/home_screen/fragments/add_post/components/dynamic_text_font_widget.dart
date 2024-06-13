import 'package:flutter/material.dart';

class DynamicTextFontWidget extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onStyleChanged;

  const DynamicTextFontWidget({super.key, required this.onStyleChanged});

  @override
  _DynamicTextFontWidgetState createState() => _DynamicTextFontWidgetState();
}

class _DynamicTextFontWidgetState extends State<DynamicTextFontWidget> {
  String _fontFamily = 'Roboto';
  double _fontSize = 20.0;
  Color _fontColor = Colors.black;
  FontWeight _fontWeight = FontWeight.normal;

  final List<String> _fontFamilies = ['Roboto', 'Arial', 'Courier New', 'Times New Roman'];

  void _updateStyle() {
    widget.onStyleChanged({
      'fontFamily': _fontFamily,
      'fontSize': _fontSize,
      'fontColor': _fontColor,
      'fontWeight': _fontWeight,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _fontFamily,
                    decoration: const InputDecoration(
                      labelText: 'Font Family',
                      border: OutlineInputBorder(),
                    ),
                    items: _fontFamilies.map((String family) {
                      return DropdownMenuItem<String>(
                        value: family,
                        child: Text(family),
                      );
                    }).toList(),
                    onChanged: (String? newFamily) {
                      setState(() {
                        _fontFamily = newFamily ?? 'Roboto';
                        _updateStyle();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<FontWeight>(
                    isExpanded: true,
                    value: _fontWeight,
                    decoration: const InputDecoration(
                      labelText: 'Font Weight',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: FontWeight.normal,
                        child: Text('Normal'),
                      ),
                      DropdownMenuItem(
                        value: FontWeight.bold,
                        child: Text('Bold'),
                      ),
                    ],
                    onChanged: (FontWeight? newWeight) {
                      setState(() {
                        _fontWeight = newWeight ?? FontWeight.normal;
                        _updateStyle();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Font Size',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 10.0,
                    max: 50.0,
                    divisions: 40,
                    label: _fontSize.round().toString(),
                    onChanged: (double newSize) {
                      setState(() {
                        _fontSize = newSize;
                        _updateStyle();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      setState(() {
                        _fontColor = Colors.red;
                        _updateStyle();
                      });
                    },
                    child: const Text('Red'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor:  Colors.green),
                    onPressed: () {
                      setState(() {
                        _fontColor = Colors.green;
                        _updateStyle();
                      });
                    },
                    child: const Text('Green'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () {
                      setState(() {
                        _fontColor = Colors.blue;
                        _updateStyle();
                      });
                    },
                    child: const Text('Blue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
