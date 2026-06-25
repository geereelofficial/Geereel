import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/cloudinary_uploader.dart';
import '../models/user_model.dart';

/// Auth stays on Firebase Auth (free, already built/tested); the user
/// profile document lives in MongoDB behind the backend API. Throws
/// [AuthException] / [ServerException] / [StorageException] on failure;
/// never returns or throws Firebase/Dio types outside this file.
abstract class AuthRemoteDataSource {
  Stream<String?> watchAuthState();

  Stream<UserModel?> watchUserProfile(String uid);

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });

  Future<UserModel> signInWithEmail({required String email, required String password});

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  Future<void> updateProfile({required String uid, String? displayName, String? bio});

  Future<String> uploadAvatar({required String uid, required File file});

  Future<void> followUser(String targetUid);

  Future<void> unfollowUser(String targetUid);

  Future<bool> isFollowing(String targetUid);

  Future<List<UserModel>> searchUsers(String query);

  /// Accounts following [uid], newest-follow-first. [page] is 0-based.
  Future<List<UserModel>> getFollowers(String uid, {required int page, required int limit});

  /// Accounts [uid] follows, newest-follow-first. [page] is 0-based.
  Future<List<UserModel>> getFollowing(String uid, {required int page, required int limit});
}

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final ApiClient _apiClient;
  final CloudinaryUploader _cloudinaryUploader;

  bool _googleSignInInitialized = false;

  ApiAuthRemoteDataSource({
    required ApiClient apiClient,
    required CloudinaryUploader cloudinaryUploader,
    fb_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _apiClient = apiClient,
       _cloudinaryUploader = cloudinaryUploader,
       _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  @override
  Stream<String?> watchAuthState() {
    return _firebaseAuth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Stream<UserModel?> watchUserProfile(String uid) {
    return Stream.fromFuture(_fetchProfile(uid));
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final available = await _isUsernameAvailable(username);
      if (!available) {
        throw const AuthException('That username is already taken.');
      }

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('Could not create account. Please try again.');
      }

      await firebaseUser.updateDisplayName(displayName);

      final response = await _apiClient.post(
        '/users',
        data: {'username': username, 'displayName': displayName},
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<UserModel> signInWithEmail({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException('Could not sign in. Please try again.');
      }
      return _fetchOrCreateProfile(firebaseUser);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google sign-in failed: missing identity token.');
      }

      final credential = fb_auth.GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Google sign-in failed. Please try again.');
      }

      return _fetchOrCreateProfile(
        firebaseUser,
        fallbackUsername: account.email.split('@').first,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Sign-in was canceled.');
      }
      throw AuthException('Google sign-in failed: ${e.description ?? e.code}');
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignInInitialized ? _googleSignIn.signOut() : Future.value(),
    ]);
  }

  @override
  Future<void> updateProfile({required String uid, String? displayName, String? bio}) async {
    final updates = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
    };
    if (updates.isEmpty) return;

    await _apiClient.patch('/users/$uid', data: updates);
    if (displayName != null) {
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    }
  }

  @override
  Future<String> uploadAvatar({required String uid, required File file}) async {
    final url = await _cloudinaryUploader.upload(file: file, folder: 'avatars');
    await _apiClient.post('/users/$uid/avatar', data: {'photoUrl': url});
    await _firebaseAuth.currentUser?.updatePhotoURL(url);
    return url;
  }

  @override
  Future<void> followUser(String targetUid) async {
    await _apiClient.post('/users/$targetUid/follow');
  }

  @override
  Future<void> unfollowUser(String targetUid) async {
    await _apiClient.delete('/users/$targetUid/follow');
  }

  @override
  Future<bool> isFollowing(String targetUid) async {
    final response = await _apiClient.get('/users/$targetUid/is-following');
    return (response.data as Map<String, dynamic>)['following'] as bool;
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _apiClient.get('/users/search', query: {'q': query});
    return (response.data as List).map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<UserModel>> getFollowers(String uid, {required int page, required int limit}) async {
    final response = await _apiClient.get(
      '/users/$uid/followers',
      query: {'page': page, 'limit': limit},
    );
    return (response.data as List).map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<UserModel>> getFollowing(String uid, {required int page, required int limit}) async {
    final response = await _apiClient.get(
      '/users/$uid/following',
      query: {'page': page, 'limit': limit},
    );
    return (response.data as List).map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<bool> _isUsernameAvailable(String username) async {
    final response = await _apiClient.get(
      '/users/username-available',
      query: {'username': username},
    );
    return (response.data as Map<String, dynamic>)['available'] as bool;
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  Future<UserModel?> _fetchProfile(String uid) async {
    try {
      final response = await _apiClient.get('/users/$uid');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on NotFoundException {
      return null;
    }
  }

  /// Fetches the backend profile for an already-authenticated Firebase
  /// user, creating one on first sign-in (e.g. first-ever Google sign-in).
  Future<UserModel> _fetchOrCreateProfile(
    fb_auth.User firebaseUser, {
    String? fallbackUsername,
  }) async {
    final existing = await _fetchProfile(firebaseUser.uid);
    if (existing != null) return existing;

    final username = fallbackUsername ?? firebaseUser.uid.substring(0, 8);
    final displayName = firebaseUser.displayName ?? username;

    final response = await _apiClient.post(
      '/users',
      data: {'username': username, 'displayName': displayName},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  String _mapFirebaseAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Choose a stronger password (at least 8 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
