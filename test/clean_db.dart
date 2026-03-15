import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String projectId = 'digital-plug';
  print('Running Firestore cleanup script...');
  
  try {
    // 1. Fetch all businesses
    final url = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/businesses');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      print('Failed to load businesses: ${response.statusCode} - ${response.body}');
      return;
    }
    
    final data = json.decode(response.body);
    final docs = data['documents'] as List<dynamic>? ?? [];
    
    for (var doc in docs) {
      final String name = doc['name'];
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      
      // Look for the string dates!
      bool hasStringCreatedAt = fields['createdAt'] != null && fields['createdAt']['stringValue'] != null;
      bool hasStringSubEnd = fields['subscriptionEnd'] != null && fields['subscriptionEnd']['stringValue'] != null;
      
      if (hasStringCreatedAt || hasStringSubEnd) {
        print('Found corrupted business: $name');
        final deleteUrl = Uri.parse('https://firestore.googleapis.com/v1/$name');
        final delResponse = await http.delete(deleteUrl);
        if (delResponse.statusCode == 200) {
          print('Successfully deleted corrupted business document.');
        } else {
          print('Failed to delete: ${delResponse.statusCode} - ${delResponse.body}');
        }
      }
    }
    
    // 2. Fetch all users
    final usersUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users');
    final usersResponse = await http.get(usersUrl);
    if (usersResponse.statusCode == 200) {
      final usersData = json.decode(usersResponse.body);
      final userDocs = usersData['documents'] as List<dynamic>? ?? [];
      
      for (var doc in userDocs) {
        final String name = doc['name'];
        final fields = doc['fields'] as Map<String, dynamic>? ?? {};
        
        bool hasStringCreatedAt = fields['createdAt'] != null && fields['createdAt']['stringValue'] != null;
        
        if (hasStringCreatedAt) {
          print('Found corrupted user: $name');
          final deleteUrl = Uri.parse('https://firestore.googleapis.com/v1/$name');
          final delResponse = await http.delete(deleteUrl);
          if (delResponse.statusCode == 200) {
            print('Successfully deleted corrupted user document.');
          } else {
            print('Failed to delete user: ${delResponse.statusCode}');
          }
        }
      }
    }
    
    print('Cleanup complete!');
    
  } catch (e) {
    print('Error: $e');
  }
}
