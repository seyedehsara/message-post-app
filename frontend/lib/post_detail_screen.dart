import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final dynamic post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _comments = widget.post['comments'] ?? [];
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final response = await http.post(
      Uri.parse('https://crystalloids-candidates.ew.r.appspot.com/posts/${widget.post['id']}/comments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'author': user.email,
        'body': _commentController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _comments.add({
          'author': user.email,
          'body': _commentController.text,
          'date': DateTime.now().toIso8601String()
        });
        _commentController.clear();
      });
    } else {
      print('Failed to add comment: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.post['subject'] ?? 'Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(widget.post['body'] ?? '', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return ListTile(
                    title: Text(comment['body']),
                    subtitle: Text('By ${comment['author']}'),
                  );
                },
              ),
            ),
            const Divider(),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Add a comment'),
            ),
            ElevatedButton(
              onPressed: _addComment,
              child: const Text('Post Comment'),
            ),
          ],
        ),
      ),
    );
  }
}
