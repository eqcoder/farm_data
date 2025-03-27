import 'package:farm_data/crop_config/crop_default.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final Schema schema = Schema.object(
  properties: {
    '화방별조사': Schema.array(nullable: false,
      items: Schema.object(
        properties: {
          '개체': Schema.integer(nullable: false),
          '화방': Schema.array(nullable: false,
            items: Schema.object(nullable: false,
              properties: {
                '화방번호': Schema.integer(nullable: false),
                '꽃대': Schema.integer(nullable: false),
                '개화수': Schema.integer(nullable: false),
                '착과': Schema.integer(nullable: false),
                '수확': Schema.integer(nullable: false),
              },
              requiredProperties: ['화방번호', '꽃대', '개화수', '착과', '수확'],
            ),
          ),
        },
      ),
    ),
    '기본조사': Schema.array(nullable: false,
      items: Schema.object(nullable: false,
        properties: {
          '개체': Schema.integer(nullable: false),
          '생장길이': Schema.number(nullable: false),
          '엽수': Schema.integer(nullable: false),
          '엽장': Schema.number(nullable: false),
          '엽폭': Schema.number(nullable: false),
          '줄기굵기': Schema.number(nullable: false),
          '화방높이': Schema.number(nullable: false),
        },
        requiredProperties: ['개체', '생장길이', '엽수', '엽장', '엽폭', '줄기굵기', '화방높이'],
      ),
    ),
  },
);
// class FlowerClusterDataScaler{
//   ListView.builder(
//       itemCount: _data.length,
//       itemBuilder: (context, rowIndex) {
//         final rowData = _data[rowIndex];
//         return Row(
//           children: rowData.asMap().entries.map((entry) {
//             final colIndex = entry.key;
//             final cellData = entry.value;
//             double width = 100.0; // 기본 셀 너비

//             if (rowIndex == 2 && colIndex == 1) {
//               width = 200.0; // "Data 5 and 6" 셀 너비
//             }

//             return Container(
//               width: width,
//               padding: EdgeInsets.all(8.0),
//               decoration: BoxDecoration(
//                 border: Border.all(),
//               ),
//               child: Text(cellData),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
// }
// }
class Tomato extends CropDefault{
  Tomato(super.data);

}
