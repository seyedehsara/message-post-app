import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'new_post_screen.dart';
import 'comments_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TabbedHomeScreen extends StatefulWidget {
  const TabbedHomeScreen({super.key});

  @override
  State<TabbedHomeScreen> createState() => _TabbedHomeScreenState();
}

class _TabbedHomeScreenState extends State<TabbedHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = FirebaseAuth.instance.currentUser;

  List<dynamic> _myPosts = [];
  List<dynamic> _allPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse('https://crystalloids-candidates.ew.r.appspot.com/posts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedMessages = json.decode(response.body);

        final userEmail = user?.email ?? '';
        final userMessages =
            fetchedMessages.where((msg) => msg['author'] == userEmail).toList();

        setState(() {
          _myPosts = userMessages;
          _allPosts = fetchedMessages;
        });
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      print('Error fetching posts: $e');
    }
  }

  Widget buildPostCard(Map<String, dynamic> post, {bool isOwner = false}) {
    final created = post['creation_date'] ?? post['created_at'];
    final updated = post['update_date'] ?? post['updated_at'];
    final comments = post['comments'] ?? [];

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(post['subject']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post['body']),
            if (created != null) Text("Created: $created"),
            if (updated != null) Text("Updated: $updated"),
            const SizedBox(height: 8),
            if (comments.isNotEmpty)
              const Text("Comments:", style: TextStyle(fontWeight: FontWeight.bold)),
            for (var comment in comments)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("- ${comment['author']}: ${comment['body']}"),
              ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommentsScreen(postId: post['id']),
                  ),
                );
              },
              child: const Text("Add Comment"),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: isOwner
            ? () async {
                final bool? shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewPostScreen(post: post),
                  ),
                );
                if (shouldRefresh == true) {
                  fetchPosts();
                }
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "My Posts"),
            Tab(text: "All Posts"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _myPosts.isEmpty
              ? const Center(child: Text('No posts found'))
              : ListView(
                  children: _myPosts
                      .map((post) => buildPostCard(post, isOwner: true))
                      .toList(),
                ),
          _allPosts.isEmpty
              ? const Center(child: Text('No posts found'))
              : ListView(
                  children: _allPosts
                      .map((post) => buildPostCard(post, isOwner: post['author'] == user?.email))
                      .toList(),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool? shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewPostScreen(),
            ),
          );

          if (shouldRefresh == true) {
            fetchPosts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
