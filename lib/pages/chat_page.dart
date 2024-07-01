import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:xis/pages/authentication/register_page.dart';
import 'package:xis/pages/inicio_chat_page.dart';

import 'authentication/login_page.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final PageController _pageController =
      PageController(); // Single PageController instance

  int _currentIndex = 0; // Track the current tab index

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _firestore.collection('messages').add({
        'text': _messageController.text,
        'sender': _auth.currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(
        index); // Navigate to the selected page using the PageController
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController, // Assign the PageController to PageView
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Chat Page Content
          Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: _firestore
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!.docs;
                    List<Widget> messageWidgets = [];
                    for (var message in messages) {
                      final messageText = message['text'];
                      final messageSender = message['sender'];
                      final Timestamp? messageTimestamp =
                          message['timestamp'] as Timestamp?;
                      final String messageTime = messageTimestamp != null
                          ? DateFormat('hh:mm a')
                              .format(messageTimestamp.toDate())
                          : 'Sending...';

                      final messageWidget = Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment:
                              messageSender == _auth.currentUser?.email
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageSender ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            //one commit preview
                            Material(
                              borderRadius: BorderRadius.circular(10.0),
                              elevation: 5.0,
                              color: messageSender == _auth.currentUser?.email
                                  ? Colors.green
                                  : Colors.grey[300],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      messageText,
                                      style: TextStyle(
                                        color: messageSender ==
                                                _auth.currentUser?.email
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      messageTime,
                                      style: TextStyle(
                                        color: messageSender ==
                                                _auth.currentUser?.email
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      messageWidgets.add(messageWidget);
                    }
                    return ListView(
                      reverse: true,
                      children: messageWidgets,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter your messagehhbbs',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Profile Page Content
          InicioChatPage(),
          // Settings Page Content
          RegisterPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped, // Update onTap to use _onTabTapped
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
