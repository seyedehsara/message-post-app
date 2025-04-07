import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'new_post_screen.dart';
import 'comments_screen.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messages',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.hasData ? const TabbedHomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}

class TabbedHomeScreen extends StatefulWidget {
  const TabbedHomeScreen({super.key});

  @override
  State<TabbedHomeScreen> createState() => _TabbedHomeScreenState();
}

class _TabbedHomeScreenState extends State<TabbedHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
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
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MyPostsScreen(),
          AllPostsScreen(),
        ],
      ),
    );
  }
}

class PostListScreen extends StatefulWidget {
  final bool onlyMine;
  const PostListScreen({super.key, required this.onlyMine});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  List<dynamic> _messages = [];
  final user = FirebaseAuth.instance.currentUser;

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('https://crystalloids-candidates.ew.r.appspot.com/posts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedMessages = json.decode(response.body);

        List<dynamic> sortedMessages = widget.onlyMine
            ? fetchedMessages.where((msg) => msg['author'] == user?.email).toList()
            : fetchedMessages;

        sortedMessages.sort((a, b) {
          final aDate = DateTime.tryParse(a['creation_date'] ?? a['created_at'] ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b['creation_date'] ?? b['created_at'] ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        if (!mounted) return;
        setState(() {
          _messages = sortedMessages;
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  void _openComments(String postId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentsScreen(postId: postId),
      ),
    );
    fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _messages.isEmpty
          ? const Center(child: Text('No messages found or still loading...'))
          : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final post = _messages[index];
                final created = post['creation_date'] ?? post['created_at'];
                final updated = post['update_date'] ?? post['updated_at'];
                final comments = post['comments'] ?? [];
                final author = post['author'] ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(post['subject']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Author: $author"),
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
                          onPressed: () => _openComments(post['id']),
                          child: const Text("Add Comment"),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: widget.onlyMine
                        ? () async {
                            final bool? shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewPostScreen(post: post),
                              ),
                            );
                            if (shouldRefresh == true) {
                              fetchMessages();
                            }
                          }
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: widget.onlyMine
          ? FloatingActionButton(
              onPressed: () async {
                final bool? shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewPostScreen(),
                  ),
                );
                if (shouldRefresh == true) {
                  fetchMessages();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PostListScreen(onlyMine: true);
  }
}

class AllPostsScreen extends StatelessWidget {
  const AllPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PostListScreen(onlyMine: false);
  }
}
