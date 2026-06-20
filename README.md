# Geereel

A TikTok-style short-video app: vertical full-screen feed, video/image posting, 1:1 chat, and profiles, built with Flutter + Firebase.

Support: Geereelofficial@gmail.com

## Stack

- **Flutter** (Dart 3, null-safe), clean architecture (`presentation` / `domain` / `data` per feature)
- **Riverpod** with code generation (`riverpod_generator` + `build_runner`) for state management
- **go_router** for navigation, including a `StatefulShellRoute` for the bottom-nav tabs
- **Firebase**: Auth (email/password + Google), Firestore, Storage, Cloud Messaging
- **freezed** / **json_serializable** for immutable entities and JSON (de)serialization
- **video_player** for feed playback, with a small custom controller cache that keeps the
  current and adjacent videos buffered for instant-feeling swipes

## Prerequisites

- Flutter SDK (this project targets the `^3.12.2` Dart SDK constraint in `pubspec.yaml`; run `flutter --version` to confirm yours is recent enough)
- Android Studio or VS Code with the Flutter/Dart plugins
- A Google account to create a Firebase project
- A physical Android device or emulator (this MVP targets Android first; see "iOS" below)

## 1. Install dependencies

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The second command generates the `*.freezed.dart` / `*.g.dart` files (entities, models, and
Riverpod providers). These are gitignored — **run this after every `git pull` or `flutter pub get`
that touches a `@freezed` class or a `@riverpod` provider**, and any time the build complains
about a missing `_$ClassName` or `xProvider`.

## 2. Create and configure the Firebase project

### 2.1 Create the project

1. Go to the [Firebase console](https://console.firebase.google.com/) and create a new project (any name, e.g. "Geereel").
2. You don't need Google Analytics for the MVP — you can skip it.

### 2.2 Enable the services this app uses

In the Firebase console, for your new project:

| Service | Where | What to do |
|---|---|---|
| **Authentication** | Build → Authentication → Sign-in method | Enable **Email/Password** and **Google** |
| **Firestore Database** | Build → Firestore Database | Create database → **Production mode** → pick a region |
| **Storage** | Build → Storage | Get started → **Production mode** (same region as Firestore) |
| **Cloud Messaging** | Build → Cloud Messaging | Nothing to do — it's enabled automatically with the project |

Then apply the security rules in this repo:

- Firestore Database → Rules → paste the contents of [`firestore.rules`](./firestore.rules) → Publish
- Storage → Rules → paste the contents of [`storage.rules`](./storage.rules) → Publish

### 2.3 Register the Android app

1. In the Firebase console, click the Android icon to add an app.
2. **Android package name**: `com.geereel.geereel` (this is the `applicationId` set in
   `android/app/build.gradle.kts` — change it there first if you want a different id, *before*
   registering, so they match).
3. Download the generated **`google-services.json`** and place it at `android/app/google-services.json`.
   - This file is **not secret** (it's bundled into every APK and is not a credential by itself) —
     it's fine to commit it. Firestore/Storage security rules are the actual access boundary.

### 2.4 Get a SHA-1 fingerprint (required for Google Sign-In)

Google Sign-In on Android needs your debug-signing certificate's SHA-1 registered on the Firebase
Android app config (Project settings → your Android app → "Add fingerprint").

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

(On macOS/Linux, replace the path with `~/.android/debug.keystore`.) Copy the `SHA1` value into
the Firebase console. Without this step, email/password auth still works, but **Google Sign-In
will fail**.

### 2.5 Generate `firebase_options.dart`

The easiest path is the FlutterFire CLI, which reads your Firebase project and writes
`lib/firebase_options.dart` for you:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select your Firebase project, choose **Android** only (this MVP doesn't configure iOS yet — see
below), and let it overwrite `lib/firebase_options.dart`. It will also offer to write/update
`android/app/google-services.json` for you, which is fine if you skipped step 2.3.

If you'd rather not install the CLI, you can instead manually copy the four values
(`apiKey`, `appId`, `messagingSenderId`, `projectId`, `storageBucket`) from
Project settings → General → Your apps, into the `android` constant in `lib/firebase_options.dart`.

## 3. Run the app

```bash
flutter run
```

The app boots to a splash screen, resolves the signed-in state, and routes to `/login` or `/feed`
accordingly (see `lib/app/router/app_router.dart`).

## iOS

This MVP was scaffolded Android-first (the dev machine here didn't have a Mac/iOS toolchain).
To add iOS later:

```bash
flutter create --platforms=ios .
flutterfire configure   # re-run and select iOS too, to add GoogleService-Info.plist
```

You'll also need to register an iOS app in the Firebase console and set up APNs for push
notifications — neither is wired up yet.

## Project structure

```
lib/
  app/                    # theme, go_router config, bottom-nav shell
  core/                   # cross-feature: constants, Result/Failure types, shared widgets, Firebase SDK providers
  features/
    auth/                 # signup/login/Google sign-in, profile read/update, avatar upload
    feed/                 # the Post entity/repository (shared with upload), vertical video feed
    comments/             # comment list + composer bottom sheet
    upload/                # pick/record media, caption, post (uses feed's CreatePost use case)
    profile/               # profile screen, edit profile, settings/about
    chat/                  # 1:1 real-time chat
    notifications/          # FCM token registration (infra only, no UI yet)
    live/                  # placeholder — intentionally empty
    groups/                # placeholder — intentionally empty
```

Each feature (except the infra-only `notifications`) follows the same internal layering:

- **domain/**: `entities` (plain `freezed` data classes), `repositories` (abstract interfaces),
  `usecases` (one class per action, calling the repository)
- **data/**: `models` (Firestore-shaped `freezed` classes with `fromJson`/`toJson`/`fromFirestore`
  and a `toEntity()` mapper), `datasources` (the only place that touches the Firebase SDK
  directly), `repositories` (implements the domain interface, translates exceptions → `Failure`s)
- **presentation/**: `providers` (Riverpod, code-generated with `@riverpod`), `screens`, `widgets`

`PostRepository` lives under `features/feed/domain/` but is also used by `features/upload/` — both
operate on the same `posts` collection, so the upload feature's `UploadController` just calls
`CreatePost` (a feed use case) rather than duplicating post-writing logic.

### Why `Result<T>` instead of try/catch everywhere

`core/utils/result.dart` defines a small `Result<T>` sealed type (`Ok<T>` / `Err<T>`). Datasources
throw the typed exceptions in `core/errors/exceptions.dart`; repositories catch those and return
`Err(Failure)` instead of throwing, so presentation code handles failures with an exhaustive
`switch` instead of unstructured try/catch creeping into widgets.

## Firestore schema

```
users/{uid}
  username, displayName, email, photoUrl, bio,
  followersCount, followingCount, postsCount, createdAt
  └─ followers/{followerUid}, following/{followingUid}   (reserved for a future follow feature)
  └─ fcmTokens/{token}        { platform, createdAt }     (one doc per signed-in device)

posts/{postId}
  authorId, authorUsername, authorPhotoUrl (denormalized),
  mediaType: "video"|"image", mediaUrl, thumbnailUrl,
  caption, durationSeconds, width, height,
  likesCount, commentsCount, sharesCount, viewsCount,
  status: "processing"|"published"|"failed", createdAt
  └─ likes/{uid}              { createdAt }
  └─ comments/{commentId}     { authorId, authorUsername, authorPhotoUrl, text,
                                 likesCount, parentCommentId, createdAt }

chats/{chatId}                # chatId = sorted "uidA_uidB" — deterministic per pair
  participantIds: [uidA, uidB]
  participantInfo: { uidA: {username, photoUrl}, uidB: {...} }
  lastMessage: { text, senderId, createdAt }, lastMessageAt
  unreadCount: { uidA: 0, uidB: 2 }
  └─ messages/{messageId}     { senderId, text, type: "text", createdAt }
```

`parentCommentId` and `messages.type` are populated/typed today even though the MVP UI doesn't use
nested replies or non-text messages — so adding either later is new code, not a data migration.
Likewise, `live/` and `groups/` are empty top-level feature folders: a future live-streaming
collection or `groups/{groupId}` collection (reusing the same `messages` subcollection shape for
group chat) slots in next to the existing features without touching them.

## Known MVP limitations / natural next steps

- **Counters are client-incremented.** `likesCount`, `commentsCount`, `viewsCount`, `sharesCount`
  are updated directly by clients (via `FieldValue.increment`), not recomputed server-side. A
  Cloud Function that recounts from the subcollections would close the small trust gap this
  leaves (a malicious client could in principle inflate its own counts).
- **No push notification triggers yet.** FCM tokens are collected and stored
  (`users/{uid}/fcmTokens/`), but nothing sends a push on a new like/comment/message — that needs
  a Cloud Function watching those collections.
- **No video thumbnail generation.** Video posts have a `thumbnailUrl` field but it's always null
  today; the profile grid shows a placeholder icon for videos instead. Generating one client-side
  (e.g. via `video_thumbnail`) or server-side (Cloud Function) is a drop-in addition.
  **No client-side video compression** either — uploads go straight to Storage at their original
  size.
- **No follow system**, even though `followersCount`/`followingCount` and the `followers`/`following`
  subcollections exist in the schema for it.
- **Share button** just increments `sharesCount` and shows a placeholder snackbar; swap in
  `share_plus` (or platform share intents) to actually open a share sheet.
- **iOS isn't configured** (see the iOS section above).
