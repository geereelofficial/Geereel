import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/providers/navigation_providers.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/feed/presentation/providers/feed_providers.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/post_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/follow_list_screen.dart';
import '../../features/profile/presentation/screens/my_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_post_viewer_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/status/presentation/screens/create_status_screen.dart';
import '../../features/status/presentation/screens/status_viewer_screen.dart';
import '../../features/upload/presentation/screens/upload_screen.dart';
import 'home_shell.dart';

part 'app_router.g.dart';

/// Bridges riverpod state changes into go_router's [Listenable]-based
/// refresh mechanism, so `redirect` re-runs whenever auth state changes
/// without rebuilding the [GoRouter] instance itself.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (previous, next) => notifyListeners());
  }
}

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    observers: [routeObserver],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final path = state.matchedLocation;
      final isSplash = path == '/splash';
      final isOnboarding = path == '/onboarding';
      final isAuthRoute = path == '/login' ||
          path == '/signup' ||
          path == '/forgot-password';

      if (authState.isLoading && !authState.hasValue) {
        return isSplash ? null : '/splash';
      }

      final isLoggedIn = authState.value != null;

      if (!isLoggedIn) {
        if (isOnboarding) return null;
        final seen = ref.read(onboardingSeenProvider);
        if (!seen) return '/onboarding';
        if (isAuthRoute) return null;
        return '/login';
      }

      // Logged in — bounce away from auth/onboarding screens
      if (isAuthRoute || isSplash || isOnboarding) return '/feed';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/upload',
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/chat/:otherUserId',
        builder: (context, state) {
          return ChatScreen(otherUserId: state.pathParameters['otherUserId']!);
        },
      ),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(
        path: '/post/:postId',
        // No-transition (rather than the default slide-in) so opening a
        // post from a profile grid or a shared link feels like landing
        // directly on that post in the feed, not navigating to a
        // different screen.
        pageBuilder: (context, state) {
          return NoTransitionPage(
            child: PostDetailScreen(postId: state.pathParameters['postId']!),
          );
        },
      ),
      GoRoute(path: '/status/create', builder: (context, state) => const CreateStatusScreen()),
      GoRoute(
        path: '/status/:authorId',
        builder: (context, state) {
          return StatusViewerScreen(authorId: state.pathParameters['authorId']!);
        },
      ),
      GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: '/profile/:uid',
        builder: (context, state) {
          return ProfileScreen(uid: state.pathParameters['uid']!);
        },
      ),
      GoRoute(
        path: '/profile/:uid/followers',
        builder: (context, state) {
          return FollowListScreen(
            uid: state.pathParameters['uid']!,
            kind: FollowListKind.followers,
          );
        },
      ),
      GoRoute(
        path: '/profile/:uid/following',
        builder: (context, state) {
          return FollowListScreen(
            uid: state.pathParameters['uid']!,
            kind: FollowListKind.following,
          );
        },
      ),
      GoRoute(
        path: '/profile/:uid/posts/:postId',
        // No-transition, matching /post/:postId, so tapping a grid tile
        // feels like landing directly on that post rather than navigating
        // to a different screen.
        pageBuilder: (context, state) {
          final tabName = state.uri.queryParameters['tab'];
          final tab = ProfilePostsTab.values.firstWhere(
            (t) => t.name == tabName,
            orElse: () => ProfilePostsTab.uploaded,
          );
          return NoTransitionPage(
            child: ProfilePostViewerScreen(
              uid: state.pathParameters['uid']!,
              tab: tab,
              initialPostId: state.pathParameters['postId']!,
            ),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/feed', builder: (context, state) => const FeedScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/chats', builder: (context, state) => const ChatListScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/me', builder: (context, state) => const MyProfileScreen())],
          ),
        ],
      ),
    ],
  );
}
