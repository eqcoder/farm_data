import '../crop_photo.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import 'package:provider/provider.dart';
import '../../appbar.dart';

class GrowthSurveyScreen extends StatefulWidget {
  final Farm farm;

  const GrowthSurveyScreen({super.key, required this.farm});
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<GrowthSurveyScreen> {

Widget _addStemCard(int farmId, int entityNum) {
  final state = context.watch<SurveyState>();
  return InkWell(
    onTap: ()async {
      // 줄기 추가 로직
      final farmInstance = FarmDatabase.instance;
      await farmInstance.addEntity(farmId, entityNum);
      await state._loadStems();
      final lastIndex = state.stems.length - 1;
      if (state.stemPageController.hasClients) {
      state.stemPageController.animateToPage(
    lastIndex,
    duration: const Duration(milliseconds: 400),
    curve: Curves.ease,
  );
    }},
    child: Card(
      color: Colors.blue[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 40, color: Colors.blue),
            SizedBox(height: 10),
            Text('새 줄기 추가', style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    
    return ChangeNotifierProvider(
      create: (_) => SurveyState(farmId: widget.farm.id!),
      child: Builder(
    builder: (context) {
      final state = context.watch<SurveyState>();
      return Scaffold(
      appBar: CustomAppBar(title: '${state.farmName} 농가 마디조사'),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: state.stemPageController,
              itemCount: state.stems.length + 1,
              itemBuilder: (ctx, index) {
                if (index >= state.stems.length) {
                  int stemNumber=index>0?state.stems[index - 1]['entity_number'] + 1:1;
                  return _addStemCard(state.farmId, stemNumber);
                }
                return _StemView(stem: state.stems[index], name:widget.farm.name);
              },
            ),
          ),
        ],
      ),
    );}));
  }
}

class SurveyState with ChangeNotifier {
  final int farmId;
  final PageController stemPageController = PageController();
  List<Map<String, dynamic>> stems = [];
  List<Map<String, dynamic>> nodes = [];
  String farmName = '';

  SurveyState({required this.farmId}) {
    _init();
  }

  Future<void> _init() async {
    final db = await FarmDatabase.instance.database;
    print(farmId);
    // 농가 정보 조회
    final farms = await db.query(
      'farms',
      where: 'id = ?',
      whereArgs: [farmId],
    );
    if (farms.isEmpty) {
      return;
    }
    farmName = farms.first['name'] as String;

    // 초기 데이터 로드
    await _loadStems();
    notifyListeners();
  }
  Future<void> updateNodeStatus(int nodeId, String newStatus) async {
    final db = FarmDatabase.instance;
    await db.updateNodeStatus(nodeId, newStatus);
    await _loadNodes(stems.first['id'] as int); // 데이터 다시 불러오기
    notifyListeners();
  }
  Future<void> _loadStems() async {
    final db = await FarmDatabase.instance.database;
    stems = await db.rawQuery('''
      SELECT stems.*,
      entities.entity_number 
      FROM stems
      INNER JOIN entities ON stems.entity_id = entities.id
      WHERE entities.farm_id = ?
      ORDER BY entities.entity_number
    ''', [farmId]);

    if (stems.isNotEmpty) {
      await _loadNodes(stems.first['id'] as int);
    }
    notifyListeners();
  }

  Future<void> _loadNodes(int stemId) async {
    final db = await FarmDatabase.instance.database;
    nodes = await db.query(
      'nodes',
      where: 'stem_id = ?',
      whereArgs: [stemId],
      orderBy: 'node_number ASC',  // 아래에서 위로 표시
    );
    notifyListeners();
  }

  // ... (나머지 메서드)
}class _AddNodeButton extends StatelessWidget {
  final int stemId;
  
  _AddNodeButton({required this.stemId});
  final farmInstance=FarmDatabase.instance;
  @override
  Widget build(BuildContext context) {
    final state = context.read<SurveyState>();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:[Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('마디 추가'),
        onPressed: () async {
          final nodeNumber = state.nodes.length + 1;
          await farmInstance.addNode(stemId, nodeNumber);
          await state._loadNodes(stemId); // 새 마디 로드
        },
      ),
    ),state.nodes.isNotEmpty?Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('마디 삭제'),
        onPressed: () async {
          final nodeNumber = state.nodes.length-1;
          await farmInstance.deleteNode(state.nodes[nodeNumber]['id']);
          await state._loadNodes(stemId); // 새 마디 로드
        },
      ),
    ):SizedBox.shrink(),]);
  }
}

class _StemView extends StatelessWidget {
  final Map<String, dynamic> stem;
  final String name;

  const _StemView({required this.stem, required this.name});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SurveyState>();
    bool isMatched = false;
    final TextEditingController _farmNameController = TextEditingController();
    state._loadNodes(stem['id'] as int); // 줄기 ID에 해당하는 마디 로드
    
    return Column(
      children: [
        

        // 마디 리스트
        Expanded(flex:10, child:
        ListView.builder(
          reverse: true,
          itemCount: state.nodes.length + 1,
          itemBuilder: (ctx, index) {
            if (index >= state.nodes.length) return _AddNodeButton(stemId: stem['id'] as int);
            final node = state.nodes[index];
            return _NodeItem(node: node);
          },
        )),

      Expanded(flex:1, child:Row(children:[Expanded(flex:5, child:Container(
  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 184, 159, 114), // 원하는 배경색
    borderRadius: BorderRadius.circular(12),
  ),
  child:Row(
        children: [Expanded(
          flex:5,
        child: Text('${stem['entity_number']}-${stem['stem_number']} 개체', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40, color: const Color.fromARGB(255, 218, 241, 221)),),
        ),
      // 오른쪽 삭제 버튼
      Expanded(flex:1,child:TextButton.icon(
  onPressed: ()async {
      final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 바깥 터치로 닫히지 않게
    builder: (context){ return StatefulBuilder(
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
              children: [Text(
        '이 작업은 되돌릴 수 없습니다!\n정말로 ${stem['entity_number']}-${stem['stem_number']} 개체를 삭제하시겠습니까?',
        style: TextStyle(
          color: Colors.red[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        '농가명($name)을 입력해야 삭제할 수 있습니다.',
        style: TextStyle(
          color: Colors.red[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      TextField(
                  controller: _farmNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: name,
                  ),
                  onChanged: (value) {
                    setState((){
                      isMatched = value == name;});
                    })])
                ,
      actions: [
        TextButton(
          child: Text('취소'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          child: Text('삭제', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(

            foregroundColor: isMatched ? Colors.red : Colors.grey,
          ),
          
          onPressed: isMatched?(){Navigator.of(context).pop(true);}:null,
        ),
      ],
    );},
  );});
if (confirm == true) {

       final farmInstance = FarmDatabase.instance;
      await farmInstance.deleteStem(stem['id']);
      await state._loadStems();
}

  },
  icon: Icon(Icons.delete, color: Colors.red, size:30),
  label: Text('개체삭제', style: TextStyle(color: Colors.red, fontSize:30, fontWeight: FontWeight.bold)),
))]))),
Expanded(flex:1,child:ElevatedButton.icon(
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          '마디조사 업로드',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(double.infinity, 48),
        ),
        onPressed: () async {}))
        ,
        SizedBox(width:16),
        Expanded(
          flex:1,child:ElevatedButton.icon(
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          '마디조사표',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(double.infinity, 48),
        ),
        onPressed: () async {}))
        ,SizedBox(width:16),
        ],
      )),],
    );
  }
}

class _NodeItem extends StatelessWidget {
  final Map<String, dynamic> node;
  
  const _NodeItem({required this.node});

  @override
  Widget build(BuildContext context) {
    final state = context.read<SurveyState>();
    final screenHeight = MediaQuery.of(context).size.height;
    final List<String> statuses = ['개화', '착과', '열매', '수확', '낙과'];
    return Container(
  height: screenHeight / 5, // ListTile의 높이에 맞게 지정
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/paprika_stem.png'), // 에셋 이미지 경로
      fit: BoxFit.fill, // 전체를 채우도록
    ),
    borderRadius: BorderRadius.circular(12), // Card 스타일을 원하면
  ),child:ListTile(
      title: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      '${node['node_number']} 번 마디',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 30,
        color: const Color.fromARGB(255, 11, 65, 19),
        letterSpacing: 1.5,
      ),
    ),
    SizedBox(width: 36),
    Row(
      children: statuses.map((status) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: status,
              groupValue: node['status'],
              onChanged: (value) async {
                if (value == null) return;
                await state.updateNodeStatus(node['id'], value);
              },
            ),
            Text(status, style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
          ],
        );
      }).toList(),
    ),
  ],
),

      trailing: Container(
  width: 300, // 원하는 크기
  height: 300,
  alignment: Alignment.center,child:Image(
  image: _getStatusImage(node['status']),
  width: 120,
  height: 120,
  fit:BoxFit.contain
)),
));
  }

  ImageProvider _getStatusImage(String status) {
    switch(status) {
      case '개화': return const AssetImage('assets/node_flower.png');
      case '착과': return const AssetImage('assets/node_smallfruit.png');
      case '수확': return const AssetImage('assets/node_harvest.png');
      case '열매': return const AssetImage('assets/node_fruit.png');
      default: return const AssetImage('assets/no_fruit.png');
    }
  }
}

// ... (나머지 위젯들)
