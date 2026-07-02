import 'dart:convert';
import 'dart:io';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin;

void main() async {
  final serviceAccountFile = File('service-account.json');
  final serviceAccountJson = jsonDecode(serviceAccountFile.readAsStringSync());
  
  final app = admin.FirebaseApp.initializeApp(
    options: admin.AppOptions(
      credential: admin.Credential.fromServiceAccount(serviceAccountFile),
      projectId: serviceAccountJson['project_id'],
    ),
  );

  final firestore = app.firestore();
  final snapshot = await firestore.collection('exams').get();

  print('Total exams in Firestore: ${snapshot.docs.length}');
  for (var doc in snapshot.docs) {
    final data = doc.data();
    print('ID: ${doc.id} | Title: ${data['title']} | Questions: ${data['questionCount']} | Status: ${data['status']}');
  }
  exit(0);
}
