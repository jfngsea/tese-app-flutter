import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: EdgeInsets.only(top: 30),
            child: Text(
              "Loading...",
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}