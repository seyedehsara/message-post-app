import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class NewPostScreen extends StatefulWidget {
  final Map<String, dynamic>? post;

  const NewPostScreen({super.key, this.post});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _subject = '';
  String _body = '';

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _subject = widget.post!['subject'];
      _body = widget.post!['body'];
    }
  }

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Anonymous';

    final isUpdating = widget.post != null;
    final url = isUpdating
        ? Uri.parse('https://crystalloids-candidates.ew.r.appspot.com/posts/${widget.post!['id']}')
        : Uri.parse('https://crystalloids-candidates.ew.r.appspot.com/posts');

    final headers = {'Content-Type': 'application/json'};
    final body = isUpdating
        ? json.encode({'subject': _subject, 'body': _body})
        : json.encode({'author': email, 'subject': _subject, 'body': _body});

    final response = isUpdating
        ? await http.put(url, headers: headers, body: body)
        : await http.post(url, headers: headers, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUpdating
              ? 'Post updated successfully.'
              : 'Post created! Email notification sent.'),
        ),
      );
      Navigator.pop(context, true); // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save post.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post != null ? 'Edit Post' : 'New Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _subject,
                decoration: const InputDecoration(labelText: 'Subject'),
                onChanged: (val) => _subject = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter subject' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _body,
                decoration: const InputDecoration(labelText: 'Body'),
                onChanged: (val) => _body = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter body' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitPost();
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
