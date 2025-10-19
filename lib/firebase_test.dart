import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTest extends StatelessWidget {
  const FirebaseTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await FirebaseFirestore.instance.collection('test').add({
              'timestamp': DateTime.now(),
              'message': 'Hello Firebase!',
            });
          },
          child: const Text('Send test data to Firestore'),
        ),
      ),
    );
  }
}
