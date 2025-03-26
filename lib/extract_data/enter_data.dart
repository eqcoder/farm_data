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
class EnterData {

  Uint8List? editedImage;
  Map<String, dynamic>? crop;

  final TextEditingController farmNameController = TextEditingController();
  final TextEditingController cropNameController = TextEditingController();
  final TextEditingController surveyDateController = TextEditingController();
  
  Future<void> getImage(ImageSource source) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? pickedFile = await _picker.pickImage(source: source);
  if (pickedFile != null) {
    editedImage=(await pickedFile.readAsBytes());
  }
  }
  
Future<void> extractImage() async {
  crop= await extractData(await cleanImage(editedImage!));
}
}






