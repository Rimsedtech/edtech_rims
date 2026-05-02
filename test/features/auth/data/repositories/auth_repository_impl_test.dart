import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bitwise_academy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUserCredential mockUserCredential;
  late MockUser mockFirebaseUser;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    fakeFirestore = FakeFirebaseFirestore();
    mockUserCredential = MockUserCredential();
    mockFirebaseUser = MockUser();

    repository = AuthRepositoryImpl(
      authDataSource: mockDataSource,
      firestore: fakeFirestore,
    );
  });

  const String tUid = 'test-uid';
  const String tEmail = 'test@example.com';
  const String tDisplayName = 'Test User';

  group('AuthRepositoryImpl', () {
    test(
      'createAccountWithEmail creates user in Firebase Auth and Firestore',
      () async {
        when(() => mockFirebaseUser.uid).thenReturn(tUid);
        when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
        when(
          () => mockDataSource.createAccountWithEmail(
            email: tEmail,
            password: 'password123',
          ),
        ).thenAnswer((_) async => mockUserCredential);

        final result = await repository.createAccountWithEmail(
          email: tEmail,
          password: 'password123',
          displayName: tDisplayName,
        );

        // Verify AuthDataSource was called
        verify(
          () => mockDataSource.createAccountWithEmail(
            email: tEmail,
            password: 'password123',
          ),
        ).called(1);

        // Verify result is success
        expect(result, isA<Success<UserEntity>>());
        final UserEntity user = (result as Success<UserEntity>).data;

        expect(user.uid, tUid);
        expect(user.email, tEmail);
        expect(user.displayName, tDisplayName);
        expect(user.role, UserRole.student);

        // Verify Firestore document was created
        final doc = await fakeFirestore.collection('users').doc(tUid).get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['email'], tEmail);
        expect(doc.data()!['displayName'], tDisplayName);
        expect(doc.data()!['role'], 'student');
      },
    );

    test('signInWithEmail returns user and updates lastLoginAt', () async {
      // 1. Pre-populate Firestore with a user profile
      await fakeFirestore.collection('users').doc(tUid).set({
        'uid': tUid,
        'email': tEmail,
        'displayName': tDisplayName,
        'role': 'admin',
        'xp': 100,
        'level': 2,
        'streakDays': 5,
        'createdAt': Timestamp.fromDate(DateTime(2025)),
        'lastLoginAt': Timestamp.fromDate(DateTime(2025)),
      });

      when(() => mockFirebaseUser.uid).thenReturn(tUid);
      when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
      when(
        () => mockDataSource.signInWithEmail(
          email: tEmail,
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockUserCredential);

      final result = await repository.signInWithEmail(
        email: tEmail,
        password: 'password123',
      );

      expect(result, isA<Success<UserEntity>>());
      final UserEntity user = (result as Success<UserEntity>).data;

      expect(user.uid, tUid);
      expect(user.email, tEmail);
      expect(user.role, UserRole.admin);
      expect(user.xp, 100);

      // Verify Firestore was updated
      final doc = await fakeFirestore.collection('users').doc(tUid).get();
      expect(doc.exists, isTrue);
      // It should have updated lastLoginAt to a server timestamp,
      // fake_cloud_firestore handles serverTimestamp resolution.
    });
  });
}
