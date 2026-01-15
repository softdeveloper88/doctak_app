import 'package:flutter/material.dart';

class CustomDropdownSearch extends StatefulWidget {
  final TextEditingController? textController;
  final String? hintText;
  final List<String>? items;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final TextStyle? dropdownTextStyle;
  final IconData? suffixIcon;
  final double? dropdownHeight;
  final Color? dropdownBgColor;
  final InputBorder? textFieldBorder;
  final EdgeInsetsGeometry? contentPadding;
  final void Function(String)? onSelect;
  final void Function(String)? onChanged;

  const CustomDropdownSearch({
    super.key,
    required this.textController,
    this.hintText,
    required this.items,
    this.hintStyle,
    this.style,
    this.dropdownTextStyle,
    this.suffixIcon,
    this.dropdownHeight,
    this.dropdownBgColor,
    this.textFieldBorder,
    this.contentPadding,
    this.onSelect,
    this.onChanged,
  });

  @override
  State<CustomDropdownSearch> createState() => _CustomDropdownSearchState();
}

class _CustomDropdownSearchState extends State<CustomDropdownSearch> {
  bool _isTapped = false;
  List<String> _filteredList = [];
  List<String> _subFilteredList = [];

  @override
  initState() {
    _filteredList = widget.items!;
    _subFilteredList = _filteredList;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ///Text Field
        TextFormField(
          controller: widget.textController,
          onChanged: (val) {
            widget.onChanged!(val);
            setState(() {
              _filteredList = _subFilteredList.where((element) => element.toLowerCase().contains(widget.textController!.text.toLowerCase())).toList();
            });
          },
          validator: (val) => val!.isEmpty ? 'Field can\'t empty' : null,
          style: widget.style ?? TextStyle(color: Colors.grey.shade800, fontSize: 16.0),
          onTap: () => setState(() => _isTapped = !_isTapped),
          decoration: InputDecoration(
            // labelStyle: const TextStyle(decoration: TextDecoration.none,),
            border: widget.textFieldBorder ?? InputBorder.none,
            hintText: widget.hintText ?? "Write here...",
            hintStyle: widget.hintStyle ?? const TextStyle(fontSize: 16.0, color: Colors.black),
            suffixIcon: Icon(widget.suffixIcon ?? Icons.search, size: 25),
            contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            isDense: true,
            suffixIconConstraints: BoxConstraints.loose(MediaQuery.of(context).size),
            suffix: widget.textController!.text.isEmpty
                ? const SizedBox()
                : InkWell(
                    onTap: () {
                      widget.textController!.clear();
                      setState(() => _filteredList = widget.items!);
                    },
                    child: const Icon(Icons.clear, color: Colors.blue),
                  ),
          ),
        ),

        ///Dropdown Items
        _isTapped && _filteredList.isNotEmpty
            ? Container(
                height: widget.dropdownHeight ?? 150.0,
                color: widget.dropdownBgColor ?? Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView.builder(
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() => _isTapped = !_isTapped);
                        widget.textController!.text = _filteredList[index];
                        widget.onSelect?.call(_filteredList[index]); // Call the callback function
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(_filteredList[index], style: widget.dropdownTextStyle ?? TextStyle(color: Colors.grey.shade800, fontSize: 16.0)),
                      ),
                    );
                  },
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
