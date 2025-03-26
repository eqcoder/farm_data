import 'package:farm_data/crop_config/crop_default.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'gemini.dart';
import 'clean_image.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'clean_image.dart';
import 'gemini.dart';
import '../crop_config/schema.dart';
import 'android_screen.dart';
import 'windows_screen.dart';

class EnterDataScreen extends StatefulWidget {
  const EnterDataScreen({super.key});

  @override
  State<EnterDataScreen> createState() => _EnterDataScreenState();
}

class _EnterDataScreenState extends State<EnterDataScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('야장추출'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child:
            Platform.isAndroid
                ? AndroidEnterDataLayout()
                : WindowsEnterDataLayout(),
      ),
    );
  }

  // CropDefault setCrop(Map<String, dynamic> data){
  //   if data["작물명"]=="토마토"
  // }
}