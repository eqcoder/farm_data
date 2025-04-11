import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'provider.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _originfolderController;
  late TextEditingController _customfolderController;
  late List<TextEditingController> _memberControllers;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _originfolderController = TextEditingController(text: settings.originfolderPath);
    _customfolderController = TextEditingController(text: settings.customfolderPath);
    _memberControllers = settings.groupMembers
        .map((member) => TextEditingController(text: member))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return AlertDialog(
      title: const Text('환경설정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 폴더 경로 선택
            _buildOriginFolderSelector(),
            const SizedBox(height: 20),
            _buildCustomFolderSelector(),
            const SizedBox(height: 20),
            // 조 선택
            _buildGroupSelector(),
            const SizedBox(height: 20),
            // 조원 입력
            _buildMemberInput(),
            const SizedBox(height: 20),
            // 다크 모드 토글
            _buildDarkModeToggle(),
          ],
        ),
      ),
      actions: [
        // 취소 버튼
        TextButton(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        // 저장 버튼
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {
            settings.saveSettings();
            Navigator.pop(context);
          },
          child: const Text('저장'),
        ),
      ],
    );
  }

  Widget _buildOriginFolderSelector() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _originfolderController,
            decoration: const InputDecoration(
              hintText: "N조 폴더를 선택하세요.",
              labelText: 'N조 폴더경로',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: ()async{
            final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      _originfolderController.text = path;
      Provider.of<SettingsProvider>(context, listen: false).setOriginFolderPath(path);
    }
          }),
      ],
    );
  }
  Widget _buildCustomFolderSelector() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customfolderController,
            decoration: const InputDecoration(
              hintText: "데이터보관 폴더를 선택하세요.",
              labelText: '데이터보관 폴더 경로',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: ()async{
            final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      _customfolderController.text = path;
      Provider.of<SettingsProvider>(context, listen: false).setCustomFolderPath(path);
    }
          }
        ),
      ],
    );
  }

  Widget _buildGroupSelector() {
    return DropdownButtonFormField<int>(
      value: Provider.of<SettingsProvider>(context).selectedGroup,
      items: List.generate(6, (index) => index + 1)
          .map((group) => DropdownMenuItem(
                value: group,
                child: Text('$group 조'),
              ))
          .toList(),
      onChanged: (value) {
        Provider.of<SettingsProvider>(context, listen: false)
            .setSelectedGroup(value!);
      },
      decoration: const InputDecoration(
        labelText: '조 선택',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMemberInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('조원 (최대 3명)'),
        ..._memberControllers
            .asMap()
            .entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: entry.value,
                    decoration: const InputDecoration(
                      hintText: '조원 이름',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final members = _memberControllers
                          .map((controller) => controller.text)
                          .where((member) => member.isNotEmpty)
                          .toList();
                      Provider.of<SettingsProvider>(context, listen: false)
                          .setGroupMembers(members);
                    },
                  ),
                ))
            .toList(),
        if (_memberControllers.length < 3)
          TextButton(
            onPressed: () {
              setState(() {
                _memberControllers.add(TextEditingController());
              });
            },
            child: const Text('+ 조원 추가'),
          ),
      ],
    );
  }

  Widget _buildDarkModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('다크 모드'),
        Switch(
          value: Provider.of<SettingsProvider>(context).isDarkMode,
          onChanged: (value) {
            Provider.of<SettingsProvider>(context, listen: false)
                .toggleDarkMode(value);
          },
        ),
      ],
    );
  }
}
