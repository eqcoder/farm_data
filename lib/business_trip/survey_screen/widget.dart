import 'package:googleapis/chromepolicy/v1.dart';

import 'crop_screen/paprika_survey_screen.dart';
import 'package:flutter/material.dart';
import '../../../farm/schema.dart';
import '../../../crop/crop.dart';
import 'package:flutter/cupertino.dart';

class CropInputFields extends StatefulWidget {
  final List<CropField> fields;
  final Map<String, dynamic>? initialValues;
  final void Function(Map<String, dynamic>)? onChanged;

  const CropInputFields({
    super.key,
    required this.fields,
    this.initialValues,
    this.onChanged,
  });

  @override
  State<CropInputFields> createState() => _CropInputFieldsState();
}

class _CropInputFieldsState extends State<CropInputFields> {
  late Map<String, dynamic> values;

  @override
  void initState() {
    super.initState();
    values = {};
    for (final field in widget.fields) {
      values[field.label] = widget.initialValues?[field.label] ?? field.min;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [for (final field in widget.fields) _buildFieldPicker(field)],
    );
  }

  Widget _buildFieldPicker(CropField field) {
    final List<double> valueList = [];
    for (double i = field.min; i <= field.max; i += field.step) {
      valueList.add(double.parse(i.toStringAsFixed(2)));
    }
    int selectedIndex = valueList.indexWhere((v) => v == values[field.label]);
    if (selectedIndex == -1) selectedIndex = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            field.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 100,
          height: 120,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: selectedIndex,
            ),
            itemExtent: 36,
            onSelectedItemChanged: (index) {
              setState(() {
                values[field.label] =
                    field.type == int
                        ? valueList[index].toInt()
                        : valueList[index];
                widget.onChanged?.call(values);
              });
            },
            children:
                valueList.map((value) {
                  return Center(
                    child: Text(
                      field.type == int
                          ? value.toInt().toString()
                          : value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> getValues() => values;
}

Future<Map<String, dynamic>?> showBasicSurveyInputDialog({
  required BuildContext context,
  required Crop crop,
  Map<String, dynamic>? initialValues,
}) async {
  final formKey = GlobalKey<_CropInputFieldsState>();
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("${crop.name} 기본조사"),
        content: SizedBox(
          width: 300,
          child: CropInputFields(
            key: formKey,
            fields: crop.fields,
            initialValues: initialValues,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final values = formKey.currentState?.getValues();
              Navigator.pop(context, values);
            },
            child: const Text('저장'),
          ),
        ],
      );
    },
  );
}

class BasicSurveyInputPage extends StatelessWidget {
  final String title;
  final List<CropField> fields;
  final Map<String, dynamic>? initialValues;

  const BasicSurveyInputPage({
    super.key,
    required this.title,
    required this.fields,
    this.initialValues,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<_CropInputFieldsState>();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CropInputFields(
          key: formKey,
          fields: fields,
          initialValues: initialValues,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final values = formKey.currentState?.getValues();
          Navigator.pop(context, values);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}

Future<String?> showAddEntityDialog({
  required BuildContext context,
  required List<String> entities,
  required String title,
}) async {
  String entityNumber = entities.first;
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('개체번호: '),
                DropdownButton<String>(
                  value: entityNumber,
                  items:
                      entities
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      entityNumber = value;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, entityNumber);
            },
            child: const Text('추가'),
          ),
        ],
      );
    },
  );
}

Future<bool> showDeleteConfirmDialog({
  required BuildContext context,
  required String description,
  required String hintText,
  String confirmButtonText = '삭제',
}) async {
  final TextEditingController controller = TextEditingController();
  bool isMatched = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 32),
                SizedBox(width: 8),
                Text('정말 삭제하시겠습니까?', style: TextStyle(color: Colors.red)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '이 작업은 되돌릴 수 없습니다!\n정말로 $description를(을) 삭제하시겠습니까?',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '농가명($hintText)를(을) 입력해야 삭제할 수 있습니다.',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(hintText: hintText),
                  onChanged: (value) {
                    setState(() {
                      isMatched = value == hintText;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('취소'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: isMatched ? Colors.red : Colors.grey,
                ),
                onPressed:
                    isMatched ? () => Navigator.of(context).pop(true) : null,
                child: Text(
                  confirmButtonText,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return result == true;
}
