import 'package:farm_data/crop_config/crop_default.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final Schema schema = Schema.object(
  properties: {
    '생육조사': Schema.array(nullable: false,
      items: Schema.object(nullable: false,
        properties: {
          '개체': Schema.integer(nullable: false),
          '줄기번호': Schema.integer(nullable: false),
          '생장길이': Schema.number(nullable: false),
          '엽수': Schema.integer(nullable: false),
          '엽장': Schema.number(nullable: false),
          '엽폭': Schema.number(nullable: false),
          '줄기굵기': Schema.number(nullable: false),
          '화방높이': Schema.number(nullable: false),
          '개화마디': Schema.integer(nullable: false),
          '착과마디': Schema.integer(nullable: false),
          '열매마디': Schema.integer(nullable: false),
          '수확마디': Schema.integer(nullable: false),
          '개화수': Schema.integer(nullable: false),
          '착과수': Schema.integer(nullable: false),
          '열매수': Schema.integer(nullable: false),
          '수확수': Schema.integer(nullable: false),
        },
        requiredProperties: ['개체', '줄기번호', '생장길이', '엽수', '엽장', '엽폭', '줄기굵기', '화방높이', '개화마디', '착과마디', '열매마디', '수확마디', '개화수', '착과수', '열매수', '수확수'],
      ),
    ),
  },
);

class Tomato {
  int entity;
  int stemNumber;
  double growthLength;
  int leafNumber;
  double leafLength;
  double leafWidth;
  double stemThickness;
  double flowerHeight;
  int floweringNode;
  int fruitingNode;
  int fruitNode;
  int harvestNode;
  int floweringNumber;
  int fruitingNumber;
  int fruitNumber;
  int harvestNumber;
  Tomato({
    required this.entity,
    required this.stemNumber,
    required this.growthLength,
    required this.leafNumber,
    required this.leafLength,
    required this.leafWidth,
    required this.stemThickness,
    required this.flowerHeight,
    required this.floweringNode,
    required this.fruitingNode,
    required this.fruitNode,
    required this.harvestNode,
    required this.floweringNumber,
    required this.fruitingNumber,
    required this.fruitNumber,
    required this.harvestNumber,
  });
}

class PepperWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  const PepperWidget({super.key, required this.data});

  @override
  State<PepperWidget> createState() => _PepperWidgetState();
}

class _PepperWidgetState extends State<PepperWidget> {
  
  final List<String> _columnHeaders = ['개체', '줄기번호', '생장길이', '엽수', '엽장', '엽폭', '줄기굵기', '화방높이', '개화마디', '착과마디', '열매마디', '수확마디', '개화수', '착과수', '열매수', '수확수'];
  

 void _editCell(int rowIndex, String columnName) async {
  print("edit cell 클릭");
    TextEditingController controller =
        TextEditingController(text: widget.data[rowIndex][columnName].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$columnName 수정"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("취소")
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.data[rowIndex][columnName] = controller.text;
                });
                Navigator.pop(context);
              },
              child: Text("저장"),
            ),
          ],
        );
      },
    );
  }

  List<DataColumn> _buildColumns() {
    return _columnHeaders.map((header) => DataColumn(label:Text(header))).toList();
  }

  List<DataRow> _buildRows() {
    return widget.data.asMap().entries.map((item) {
      List<DataCell> cells = [];
      int rowIndex=item.key;
      for (var key in _columnHeaders) {
        cells.add(DataCell(Center(child:GestureDetector(onTap: ()=>_editCell(rowIndex, key), child:Text(item.value[key]?.toString() ?? ''), ))));
      }
      return DataRow(cells: cells);
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Expanded(child:DataTable(  
      columnSpacing: 30.0,
                  headingRowHeight: 50, // 헤더 높이 고정
                  dataRowHeight: 40,
          columns: _buildColumns(),
          rows:_buildRows(),
    ));
    
}
  
}
