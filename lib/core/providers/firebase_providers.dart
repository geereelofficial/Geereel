import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// Thin providers over the Firebase SDK singletons, so datasources never
/// call `XInstance.instance` directly and can be swapped/mocked in tests.
///
/// Firestore/Storage were dropped when the data layer moved to the Node/
/// MongoDB/Cloudinary backend; Auth and Messaging stay as-is (see
/// [ApiClient] for the bearer-token bridge between the two).
@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;
