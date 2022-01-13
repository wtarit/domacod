import 'package:flutter/material.dart';

class SearchResultView extends StatefulWidget {
  const SearchResultView({
    Key? key,
    required this.query,
  }) : super(key: key);
  final String query;
  @override
  _SearchResultViewState createState() => _SearchResultViewState();
}

class _SearchResultViewState extends State<SearchResultView> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.query);
  }
}
