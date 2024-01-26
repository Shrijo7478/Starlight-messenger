import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:starlight_messenger/components/chat_bubble.dart';
import 'package:starlight_messenger/components/my_text_fields.dart';
import 'package:starlight_messenger/services/chat/chat_service.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;

  const ChatPage({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> sendMessage() async {
    try {
      if (_messageController.text.isNotEmpty) {
        await _chatService.sendMessage(
          widget.receiverUserID,
          _messageController.text,
        );
        _messageController.clear();
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> sendMultimedia() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        String imageUrl = await _uploadImageToStorage(File(image.path));
        await _chatService.sendMessage(
          widget.receiverUserID,
          'Image: $imageUrl',
        );
      }
    } catch (e) {
      print('Error sending multimedia: $e');
    }
  }

  Future<String> _uploadImageToStorage(File imageFile) async {
    try {
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageReference.putFile(imageFile);
      String imageUrl = await storageReference.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image to storage: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverUserEmail,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[200],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
          _buildMultimediaButton(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessage(
        widget.receiverUserID,
        _firebaseAuth.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading..');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No messages available.');
        }

        List<DocumentSnapshot> reversedDocs =
            List.from(snapshot.data!.docs.reversed);

        return ListView(
          reverse: true,
          children: reversedDocs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    try {
      Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
      var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
          ? Alignment.centerRight
          : Alignment.centerLeft;
      return Container(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment:
                (data['senderId'] == _firebaseAuth.currentUser!.uid)
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            mainAxisAlignment:
                (data['senderId'] == _firebaseAuth.currentUser!.uid)
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            children: [
              Text(
                data['senderEmail'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              _buildMessageContent(data),
              const SizedBox(height: 5),
              Text(
                _formatTimestamp(data['timestamp']),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building message item: $e');
      return Container(); // Handle the error and return an empty container or handle accordingly
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    // Format timestamp using intl package
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('HH:mm, dd/MM/yyyy');
    return formatter.format(dateTime);
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: MyTextField(
                    controller: _messageController,
                    hintText: 'Enter Message',
                    obscureText: false,
                  ),
                ),
                IconButton(
                  onPressed: sendMultimedia,
                  icon: const Icon(
                    Icons.image,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(
              Icons.send,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultimediaButton() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  Future<void> sendImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        String imageUrl = await _uploadImageToStorage(File(image.path));
        await _chatService.sendMessage(
          widget.receiverUserID,
          'Image: $imageUrl',
        );
      }
    } catch (e, stackTrace) {
      print('Error sending image from gallery: $e');
      print(stackTrace);
    }
  }

  Widget _buildMessageContent(Map<String, dynamic> data) {
    if (data['message'].startsWith('Image: ')) {
      // Display the image
      String imageUrl = data['message'].substring('Image: '.length);
      return Image.network(
        imageUrl,
        width: 150, // Set an appropriate width
        height: 150, // Set an appropriate height
      );
    } else {
      // Display regular text message
      return ChatBubble(message: data['message']);
    }
  }
}
