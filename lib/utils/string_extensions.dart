extension StringExtensions on String {
  bool isWhitespace() => trim().isEmpty;
  bool isValidPassword() => length > 5;
}