import '../crop_photo.dart';
import 'package:flutter/material.dart';
import '../../database.dart';
import 'package:provider/provider.dart';

class Plant {
  int stemCount;
  List<NodeInfo> nodes = [];
  Plant(this.stemCount);
}

class NodeInfo {
  String state; // 'bloom', 'fruit', 'harvest', 'drop'
  int position;
  NodeInfo(this.state, this.position);
}
class GrowthSurveyScreen extends StatefulWidget {
  final Farm farm;

  const GrowthSurveyScreen({super.key, required this.farm});
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<GrowthSurveyScreen> {

Widget _addStemCard(int farmId, int entityNum) {
  final state = context.watch<SurveyState>();
  return GestureDetector(
    onTap: ()async {
      // 줄기 추가 로직
      final farmInstance = await FarmDatabase.instance;
      farmInstance.addEntity(farmId, entityNum);
      state._loadStems();
    },
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
    final state = context.watch<SurveyState>();
    
    return ChangeNotifierProvider(
      create: (_) => SurveyState(farmId: widget.farm.id!),
      child:Scaffold(
      appBar: AppBar(title: Text('${state.farmName} - 마디 관리')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: state.stemPageController,
              itemCount: state.stems.length + 1,
              itemBuilder: (ctx, index) {
                if (index >= state.stems.length) {
                  return _addStemCard(state.farmId, index);
                }
                return _StemView(entityNum: state.stems[index]['entity_number'] as int, stemNum:state.stems[index]['stem_number'] as int);
              },
            ),
          ),
        ],
      ),
    ));
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
    
    // 농가 정보 조회
    final farm = await db.query(
      'farms',
      where: 'id = ?',
      whereArgs: [farmId],
    );
    farmName = farm.first['name'] as String;

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
      SELECT stems.* 
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
      orderBy: 'node_number DESC',  // 아래에서 위로 표시
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
    
    return Container(
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
    );
  }
}

class _StemView extends StatelessWidget {
  final int entityNum;
  final int stemNum;

  const _StemView({required this.entityNum, required this.stemNum});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SurveyState>();
    final stem = state.stems[stemNum];
    
    return Stack(
      children: [
        // 배경 이미지
        Positioned.fill(
          child: Image.asset(
            'assets/paprika_stem.png',
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
          ),
        ),

        // 마디 리스트
        ListView.builder(
          reverse: true,
          itemCount: state.nodes.length + 1,
          itemBuilder: (ctx, index) {
            if (index == 0) return _AddNodeButton(stemId: stem['id'] as int);
            final node = state.nodes[index - 1];
            return _NodeItem(node: node);
          },
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$entityNum-$stemNum', style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ()
          ),
        ],
      ),],
    );
  }
}

class _NodeItem extends StatelessWidget {
  final Map<String, dynamic> node;

  const _NodeItem({required this.node});

  @override
  Widget build(BuildContext context) {
    final state = context.read<SurveyState>();
    
    return ListTile(
      title: Text('마디 ${node['node_number']}'),
      trailing: DropdownButton<String>(
        value: node['status'],
        items: const [
          DropdownMenuItem(value: '개화', child: Text('개화')),
          DropdownMenuItem(value: '착과', child: Text('착과')),
          DropdownMenuItem(value: '열매', child: Text('열매')),
          DropdownMenuItem(value: '수확', child: Text('수확')),
          DropdownMenuItem(value: '낙과', child: Text('낙과')),
        ],
        onChanged: (value) async {
          if (value == null) return;
          await state.updateNodeStatus(node['id'], value);
        },
      ),
    );
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
