import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:starlight_messenger/services/auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  void signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starlight Messenger'),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildUserList(),
    );
  }
  Widget _buildUserList(DocumentSnapshot document) {
    return StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('users').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasError) {
        return const Text('Error');
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text('Loading..');
      }
      return ListView(
        children: snapshot.data!.docs.map<Widget>((doc) => _buildUserListItem(doc)).toList()
      );
    },
    );
  }
}
