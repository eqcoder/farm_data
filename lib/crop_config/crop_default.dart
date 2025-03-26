class CropDefault {
  String? cropName;
  String? name;
  String? farmName;
  String? lastDate;
  String? date;
  Map<String, dynamic>? data;
  String? category;
  String? fileName;

  CropDefault(Map<String, dynamic> data) {
    cropName = data['작물명'];
    name = data['조사자'];
    farmName = data['농가명'];
    lastDate = data['지난_조사일'];
    date = data['조사일'];
    data = data['data'];
  }
}

class DataScaler {
  Map<String, dynamic> data;
  DataScaler(this.data);
}

