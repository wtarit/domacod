import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/database_provider.dart';
import '../grid_image_view.dart';

class CategoryThumbnail extends StatelessWidget {
  const CategoryThumbnail({
    Key? key,
    required this.thumb,
  }) : super(key: key);

  final ImageCategoryThumbnail thumb;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: thumb.thumbdata,
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        // If we have no data, display a spinner
        if (bytes == null) return Container();
        // If there's data, display it as an image
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GridImageView(
                  category: thumb.category,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(7)),
            child: GridTile(
              child: Image.file(
                bytes,
                fit: BoxFit.cover,
              ),
              footer: GridTileBar(
                backgroundColor: Colors.black,
                title: Row(
                  children: [
                    Text(thumb.category),
                    const Spacer(),
                    Text("${thumb.amount}"),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
