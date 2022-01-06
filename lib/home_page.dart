import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Widget categoryCard(String title) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        children: [Image.asset("assets/question_mark.png"), Text(title)],
      ),
    );
  }

  Widget categoryGrid() {
    List<String> categories = [
      "Cat",
      "Dog",
      "Bird",
      "Animal",
      "Person",
      "Car",
      "Bicycle",
      "Motorcycle",
      "Airplane",
    ];
    List<Widget> gridElement = [];
    for (String category in categories) {
      gridElement.add(GridTile(
        child: Image.asset("assets/question_mark.png"),
        footer: GridTileBar(
          backgroundColor: Colors.black,
          title: Text(category),
        ),
      ));
    }
    return GridView.count(
      crossAxisCount: 2,
      children: gridElement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test"),
      ),
      body: categoryGrid(),
    );
  }
}
