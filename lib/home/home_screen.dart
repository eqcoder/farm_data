import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';


class WindowsHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Staggered Grid'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StaggeredGrid.count(
          crossAxisCount: 4, // 총 열의 개수
          mainAxisSpacing: 8, // 세로 간격
          crossAxisSpacing: 8, // 가로 간격
          children: [
            StaggeredGridTile.extent(
              crossAxisCellCount: 2, // 가로로 차지하는 열의 개수
              mainAxisExtent: 100, // 세로 높이
              child: CustomTile(
                color: Colors.red,
                text: "Tile 1",
              ),
            ),
            StaggeredGridTile.extent(
              crossAxisCellCount: 1,
              mainAxisExtent: 150,
              child: CustomTile(
                color: Colors.green,
                text: "Tile 2",
              ),
            ),
            StaggeredGridTile.extent(
              crossAxisCellCount: 3,
              mainAxisExtent: 120,
              child: CustomTile(
                color: Colors.blue,
                text: "Tile 3",
              ),
            ),
            StaggeredGridTile.extent(
              crossAxisCellCount: 2,
              mainAxisExtent: 200,
              child: CustomTile(
                color: Colors.orange,
                text: "Tile 4",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTile extends StatelessWidget {
  final Color color;
  final String text;

  CustomTile({Key? key, required this.color, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
