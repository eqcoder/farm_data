import 'crops.dart';

final Map<String, Crop Function(Map<String, dynamic>)> cropFactoryMap = {
  '파프리카': (map) => Paprika.fromMap(map),
  '토마토': (map) => Tomato.fromMap(map),
  '배추': (map) => Cabbage.fromMap(map),
  '사과': (map) => Apple.fromMap(map),
  '콩': (map) => Bean.fromMap(map),
  '옥수수': (map) => Corn.fromMap(map),
};

class CropFactory {
  static Crop fromMap(Map<String, dynamic> crop) {
    final type = crop['name'] as String?;
    if (type == null || !cropFactoryMap.containsKey(type)) {
      throw Exception('지원하지 않는 작물 타입: $type');
    }
    return cropFactoryMap[type]!(crop);
  }
}
