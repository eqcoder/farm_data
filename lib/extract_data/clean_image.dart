import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';

Future<Uint8List> cleanImage(File picture) async {
  Image? image=decodeImage(picture.readAsBytesSync());
  if (image == null) {
    throw Exception('Failed to decode the image.');
  }

  // Define color ranges for masking
  final redMin = [150, 0, 0];
  final redMax = [255, 225, 225];
  // final grayMin = [190, 190, 190];
  // final grayMax = [255, 255, 230];

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;

      if (r >= redMin[0] &&
          r <= redMax[0] &&
          g >= redMin[1] &&
          g <= redMax[1] &&
          b >= redMin[2] &&
          b <= redMax[2]) {
        image.setPixel(x, y, image.getColor(255, 255, 255));
      }
    }
  }

  // // Apply gray mask
  // for (int y = 0; y < image.height; y++) {
  //   for (int x = 0; x < image.width; x++) {
  //     final pixel = image.getPixel(x, y);
  //     final r = pixel.r;
  //     final g = pixel.g;
  //     final b = pixel.b;

  //     if (r >= grayMin[0] && r <= grayMax[0] &&
  //         g >= grayMin[1] && g <= grayMax[1] &&
  //         b >= grayMin[2] && b <= grayMax[2]) {
  //       image.setPixel(x, y, image.getColor(255, 255, 255));
  //     }
  //   }
  // }

  // Convert to grayscale
  image = grayscale(image);

  // Apply Gaussian blur
  // image = gaussianBlur(image, 5);

  // Apply adaptive thresholding
  // for (int y = 0; y < image.height; y++) {
  //   for (int x = 0; x < image.width; x++) {
  //     final pixel = image.getPixel(x, y);
  //     final intensity = pixel.r; // Grayscale, so R=G=B
  //     final threshold = 128; // Simplified adaptive threshold
  //     if (intensity > threshold) {
  //       image.setPixel(x, y, image.getColor(255, 255, 255));
  //     } else {
  //       image.setPixel(x, y, image.getColor(0, 0, 0));
  //     }
  //   }
  // }

  final Uint8List pngBytes = encodePng(image) as Uint8List;
  
  // Save the processed image
  return encodeJpg(image);
}
