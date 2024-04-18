import 'package:flutter/material.dart';

class NoListItemsCard extends StatelessWidget {
  const NoListItemsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.add_box_outlined, size: 62,),
          Text("No waveforms available!"),
        ],
      ),
    );
  }
}
