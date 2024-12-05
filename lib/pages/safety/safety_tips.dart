import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SafetyTips extends StatefulWidget {
  const SafetyTips({Key? key}) : super(key: key);

  @override
  State<SafetyTips> createState() => _SafetyTipsPageState();
}

class _SafetyTipsPageState extends State<SafetyTips> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedSort = 'Title'; // Default sort
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Tips'),
        backgroundColor: const Color.fromARGB(255, 189, 220, 204),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              leading: const Icon(Icons.search),
              hintText: 'Search by title',
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Left-aligned sort dropdown
                Expanded(
                  child: DropdownMenu(
                    initialSelection: selectedSort,
                    label: const Text('Sort By'),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'Title', label: 'Title'),
                      DropdownMenuEntry(value: 'Time', label: 'Created At'),
                    ],
                    onSelected: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSort = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Tip').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No tips available. Add some tips to get started!'),
                  );
                }

                // Filter and sort tips
                final tips = snapshot.data!.docs
                    .where((tip) => tip['title']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList();

                tips.sort((a, b) {
                  if (selectedSort == 'Title') {
                    return a['title']
                        .toString()
                        .toLowerCase()
                        .compareTo(b['title'].toString().toLowerCase());
                  } else {
                    final aTime = a['createdAt'] as Timestamp?;
                    final bTime = b['createdAt'] as Timestamp?;
                    return bTime?.compareTo(aTime ?? Timestamp(0, 0)) ?? 0;
                  }
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: tips.length,
                  itemBuilder: (context, index) {
                    final tip = tips[index];
                    final isCurrentUserTip = tip['userid'] == _auth.currentUser?.uid;

                    return Card(
                      color: const Color.fromARGB(255, 189, 220, 204),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(
                          tip['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(tip['content']),
                        trailing: isCurrentUserTip
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, tip),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTip,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, QueryDocumentSnapshot tip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tip'),
        content: const Text('Are you sure you want to delete this tip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteTip(context, tip);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTip(BuildContext context, QueryDocumentSnapshot tip) async {
    try {
      await _firestore.collection('Tip').doc(tip.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tip deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete the tip: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error deleting tip: $e');
    }
  }




void _addTip() {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add a New Tip'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              maxLength: 30,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title cannot be empty';
                }
                if (value.length > 30) {
                  return 'Title cannot exceed 30 characters';
                }
                return null;
              },
            ),
            TextFormField(
              controller: contentController,
              maxLength: 200,
              maxLines: 5, // Larger box for content input
              decoration: const InputDecoration(
                labelText: 'Content',
                alignLabelWithHint: true, // Aligns label with the top of the box
                border: OutlineInputBorder(), // Adds a border for clarity
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Content cannot be empty';
                }
                if (value.length > 200) {
                  return 'Content cannot exceed 200 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final userId = _auth.currentUser?.uid;
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You must be logged in to add a tip'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _firestore.collection('Tip').add({
                'title': titleController.text,
                'content': contentController.text,
                'userid': userId,
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

}
