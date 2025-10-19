import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<Map<String, dynamic>> posts = [
    {
      "user": "Liam",
      "avatarColor": Colors.blueAccent,
      "message": "Finished my morning workout 💪 Feeling alive and ready to tackle the day!",
      "time": "2h ago",
    },
    {
      "user": "Sophie",
      "avatarColor": Colors.pinkAccent,
      "message": "Read 20 pages of ‘Deep Work’. Staying consistent feels amazing 📚",
      "time": "4h ago",
    },
    {
      "user": "Ethan",
      "avatarColor": Colors.green,
      "message": "Reflected on my day: discipline > motivation 🔥",
      "time": "1d ago",
    },
  ];

  final List<String> quotes = [
    "“Consistency compounds. Every small effort counts.”",
    "“The gap between goals and accomplishment is discipline.”",
    "“One day or day one. You decide.”",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Community"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildMotivationCard(),
            const SizedBox(height: 20),
            ...posts.map((p) => _buildPostCard(p)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _showPostDialog,
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }

  Widget _buildMotivationCard() {
    final randomQuote = (quotes..shuffle()).first;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote, color: Colors.amber, size: 32),
          const SizedBox(height: 10),
          Text(
            randomQuote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "— Reclaim Daily Motivation",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: post["avatarColor"],
            child: Text(
              post["user"][0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post["user"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post["message"],
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  post["time"],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFeed() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      posts.shuffle();
    });
  }

  void _showPostDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Share a Thought 💬"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Write something inspiring...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  posts.insert(0, {
                    "user": "You",
                    "avatarColor": Colors.purpleAccent,
                    "message": controller.text,
                    "time": "Just now",
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }
}
