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
int _selectedIndex = 0;

void deleteDialog(SurveyState state) async{{
  bool isMatched = false;
  String name = widget.farm.name;
  final stem = state.stems[_selectedIndex];
    final TextEditingController _farmNameController = TextEditingController();
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

  }}
Widget _pageDropdown(SurveyState state) {
  
  final List<String> _items=  state.stems
    .map((item) => "${item['entity_number']}-${item['stem_number']}")
    .toList();
             return 
             Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children:[
                _selectedIndex+1>widget.farm.stem_count?Expanded(flex:2,child:
      IconButton(
      icon: Icon(Icons.arrow_left, size: 70, color: const Color.fromARGB(255, 11, 65, 19),),
      onPressed: (){
  state.stemPageController.animateToPage(
    _selectedIndex-widget.farm.stem_count,
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
      })):Spacer(flex:2),

              Expanded(flex:3, child:Text('개체이동', style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 30,
        color: const Color.fromARGB(255, 11, 65, 19),
        letterSpacing: 1.5,
      ),)),
      
      Expanded(flex:2, child:
      DropdownButton<int>(
                isExpanded: true,
                value: _selectedIndex,
                style:TextStyle(fontSize: 25, color: Colors.black, fontWeight: FontWeight.bold),
                items: List.generate(
                  _items.length,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Center(child:Text(_items[index])),
                  ),
                ),
                onChanged: (int? newIndex) {
                  if (newIndex != null) {
                    setState(() {
                      _selectedIndex = newIndex;
                    });
                    // 페이지 이동
                    state.stemPageController.animateToPage(
                      newIndex,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
      )),
_selectedIndex+widget.farm.stem_count<state.stems.length?Expanded(flex:2,child:
        IconButton(
      icon: Icon(Icons.arrow_right, size: 70, color: const Color.fromARGB(255, 11, 65, 19),),
      onPressed: (){
  state.stemPageController.animateToPage(
    _selectedIndex+widget.farm.stem_count,
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
      })):Spacer(flex:2),
      Expanded(flex:3,child:ElevatedButton.icon(
        icon: Icon(Icons.delete, color: const Color.fromARGB(255, 138, 37, 37)),
        label: Text(
          '개체삭제',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: const Color.fromARGB(255, 97, 15, 15)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 234, 240, 183),
          minimumSize: Size(double.infinity, 48),
        ),
        onPressed: () async {
          deleteDialog(state);

        })),
        SizedBox(width:16),
            _selectedIndex>=state.stems.length-2?Expanded(flex:3,child:ElevatedButton.icon(
        icon: Icon(Icons.add, color: const Color.fromARGB(255, 138, 37, 37)),
        label: Text(
          '개체추가',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: const Color.fromARGB(255, 97, 15, 15)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 234, 240, 183),
          minimumSize: Size(double.infinity, 48),
        ),
        onPressed: () async {
          _addStem(state.farmId, state.stems[_selectedIndex]["entity_number"]+1, state);

        })):Spacer(flex:3),
        
SizedBox(width:16),

            ]);}

void _addStem(int farmId, int entityNum, SurveyState state)async{
      final farmInstance = FarmDatabase.instance;
      await farmInstance.addEntity(farmId, entityNum);
      await state._loadStems();
      final lastIndex = state.stems.length - widget.farm.stem_count;
      if (state.stemPageController.hasClients) {
      state.stemPageController.animateToPage(
    lastIndex,
    duration: const Duration(milliseconds: 400),
    curve: Curves.ease,
  );
    }}

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
          Expanded(flex:1,child:_pageDropdown(state)),
          Expanded(
            flex:15,
            child: PageView.builder(
              controller: state.stemPageController,
              onPageChanged: (int pageIndex) {
                setState(() {
                  if(pageIndex < state.stems.length) {
                    _selectedIndex = pageIndex; // 마지막 페이지
                  }// 페이지가 바뀌면 드롭다운 선택값 변경
                });
              },
              itemCount: state.stems.length,
              itemBuilder: (ctx, index) {
                return _StemView(stem: state.stems[index]);
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

  const _StemView({required this.stem});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SurveyState>();
    
    state._loadNodes(stem['id'] as int); // 줄기 ID에 해당하는 마디 로드
    
    return Column(
      children: [
        

        // 마디 리스트
        Expanded(flex:10, child:
        ListView.builder(
          padding:EdgeInsets.zero,
          reverse: true,
          itemCount: state.nodes.length + 1,
          itemBuilder: (ctx, index) {
            if (index >= state.nodes.length) return _AddNodeButton(stemId: stem['id'] as int);
            final node = state.nodes[index];
            return _NodeItem(node: node);
          },
        )),

      Expanded(flex:1, child:Row(children:[Expanded(flex:3, child:Container(
  margin: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 184, 159, 114), // 원하는 배경색
    borderRadius: BorderRadius.circular(12),
  ),
child:Expanded(
          flex:2,
        child: Text('${stem['entity_number']}-${stem['stem_number']} 개체', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40, color: const Color.fromARGB(255, 218, 241, 221)),),
        ))),
      // 오른쪽 삭제 버튼
Expanded(flex:2,child:ElevatedButton.icon(
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          '마디조사 업로드',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 141, 216, 144),
          minimumSize: Size(double.infinity, 48),
        ),
        onPressed: () async {}))
        ,
        SizedBox(width:16),
        Expanded(
          flex:2,child:ElevatedButton.icon(
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          '마디조사표',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 131, 209, 134),
          minimumSize: Size(double.infinity, 48),
        ),
        onPressed: () async {}))
        ,SizedBox(width:16),
        ],
      ))]);}}

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
      image: AssetImage('assets/paprika_flower.png'), // 에셋 이미지 경로
      fit: BoxFit.cover, // 전체를 채우도록
    ),
    borderRadius: BorderRadius.circular(12), // Card 스타일을 원하면
  ),child:ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    
  ],
),

      trailing: ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 1000), // 최대 너비 제한 (필요에 따라 조절)
  child: Wrap(
    spacing: 8,
    runSpacing: 4,
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
          Text(status, style: TextStyle(fontSize: 16)),
        ],
      );
    }).toList(),
  ),
),

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
