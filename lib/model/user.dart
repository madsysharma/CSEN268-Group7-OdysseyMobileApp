class User {
  final String uid;
  final String name;
  final String email;
  final String? photoURL;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.photoURL,
  });
}
