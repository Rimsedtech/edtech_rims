# Graph Report - lib  (2026-05-13)

## Corpus Check
- Corpus is ~36,807 words - fits in a single context window. You may not need a graph.

## Summary
- 713 nodes · 1009 edges · 38 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_App Shell & Routing|App Shell & Routing]]
- [[_COMMUNITY_Exam & Mock Test Layer|Exam & Mock Test Layer]]
- [[_COMMUNITY_Navigation & UI Shell|Navigation & UI Shell]]
- [[_COMMUNITY_Dashboard & Config UI|Dashboard & Config UI]]
- [[_COMMUNITY_Auth & Feature Flags|Auth & Feature Flags]]
- [[_COMMUNITY_Firebase Interceptor & Store|Firebase Interceptor & Store]]
- [[_COMMUNITY_Admin & Router Config|Admin & Router Config]]
- [[_COMMUNITY_Exam Taking & Leaderboard UI|Exam Taking & Leaderboard UI]]
- [[_COMMUNITY_Quest Repository & BLoC|Quest Repository & BLoC]]
- [[_COMMUNITY_Analytics & Dashboard Cubits|Analytics & Dashboard Cubits]]
- [[_COMMUNITY_Auth BLoC & State|Auth BLoC & State]]
- [[_COMMUNITY_Question Creation UI|Question Creation UI]]
- [[_COMMUNITY_Data Models & Entities|Data Models & Entities]]
- [[_COMMUNITY_Pixel UI Components|Pixel UI Components]]
- [[_COMMUNITY_Repository Layer & Error Handling|Repository Layer & Error Handling]]
- [[_COMMUNITY_Injection & DI Container|Injection & DI Container]]
- [[_COMMUNITY_Store Cubit & Avatar UI|Store Cubit & Avatar UI]]
- [[_COMMUNITY_Leaderboard BLoC|Leaderboard BLoC]]
- [[_COMMUNITY_Admin Dashboard|Admin Dashboard]]
- [[_COMMUNITY_Exam BLoC States|Exam BLoC States]]
- [[_COMMUNITY_Result Pattern & Failures|Result Pattern & Failures]]
- [[_COMMUNITY_Auth UI (Login  Register)|Auth UI (Login / Register)]]
- [[_COMMUNITY_User Progress Repository|User Progress Repository]]
- [[_COMMUNITY_Attempt Repository|Attempt Repository]]
- [[_COMMUNITY_Skin & Store Models|Skin & Store Models]]
- [[_COMMUNITY_Question Model & Parsing|Question Model & Parsing]]
- [[_COMMUNITY_App Typography & Theming|App Typography & Theming]]
- [[_COMMUNITY_Widget Utilities|Widget Utilities]]
- [[_COMMUNITY_Latex & Rich Text|Latex & Rich Text]]
- [[_COMMUNITY_Pixel Button & Inputs|Pixel Button & Inputs]]
- [[_COMMUNITY_Celebration Overlay|Celebration Overlay]]
- [[_COMMUNITY_Firebase Options|Firebase Options]]
- [[_COMMUNITY_Admin Upload Skin|Admin Upload Skin]]
- [[_COMMUNITY_Quest Celebration Logic|Quest Celebration Logic]]
- [[_COMMUNITY_Logger & Utilities|Logger & Utilities]]
- [[_COMMUNITY_Feature Toggle Widget|Feature Toggle Widget]]
- [[_COMMUNITY_Create Exam Flow|Create Exam Flow]]
- [[_COMMUNITY_Back Button Interceptor|Back Button Interceptor]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 33 edges
2. `package:bitwise_academy/core/constants/app_typography.dart` - 27 edges
3. `package:bitwise_academy/core/errors/result.dart` - 25 edges
4. `package:bitwise_academy/core/constants/app_colors.dart` - 23 edges
5. `package:bitwise_academy/core/constants/app_spacing.dart` - 22 edges
6. `package:flutter_bloc/flutter_bloc.dart` - 20 edges
7. `package:cloud_firestore/cloud_firestore.dart` - 15 edges
8. `package:go_router/go_router.dart` - 15 edges
9. `package:equatable/equatable.dart` - 14 edges
10. `dart:async` - 13 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities (40 total, 2 thin omitted)

### Community 0 - "App Shell & Routing"
Cohesion: 0.04
Nodes (43): package:bitwise_academy/core/router/app_router.dart, package:bitwise_academy/core/theme/app_theme.dart, package:bitwise_academy/core/widgets/quest_celebration_overlay.dart, package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart, package:go_router/go_router.dart, build, dispose, initState (+35 more)

### Community 1 - "Exam & Mock Test Layer"
Cohesion: 0.05
Nodes (42): dart:math, package:bitwise_academy/core/utils/firebase_interceptor.dart, package:bitwise_academy/shared/models/attempt_model.dart, package:bitwise_academy/shared/models/exam_model.dart, package:bitwise_academy/shared/models/question_model.dart, AttemptModel, AttemptRepository, guardedTask (+34 more)

### Community 2 - "Navigation & UI Shell"
Cohesion: 0.05
Nodes (41): package:back_button_interceptor/back_button_interceptor.dart, package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart, package:confetti/confetti.dart, package:flutter_animate/flutter_animate.dart, package:flutter/services.dart, build, dispose, Icon (+33 more)

### Community 3 - "Dashboard & Config UI"
Cohesion: 0.05
Nodes (39): package:bitwise_academy/core/widgets/mock_test_config_sheet.dart, package:bitwise_academy/core/widgets/pixel_card.dart, build, _buildSectionLabel, Center, Container, Function, GestureDetector (+31 more)

### Community 4 - "Auth & Feature Flags"
Cohesion: 0.05
Nodes (36): package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, package:logger/logger.dart, FeatureFlagService, isEnabled, setFlag, build, _buildBrandTitle (+28 more)

### Community 5 - "Firebase Interceptor & Store"
Cohesion: 0.06
Nodes (34): dart:async, dart:io, package:bitwise_academy/features/store/data/models/skin_model.dart, package:injectable/injectable.dart, FirebaseGuardedExecution, streamAction, timeout, TimeoutException (+26 more)

### Community 6 - "Admin & Router Config"
Cohesion: 0.06
Nodes (33): package:bitwise_academy/core/widgets/feature_toggle.dart, package:bitwise_academy/core/widgets/shell_scaffold.dart, package:bitwise_academy/features/admin/presentation/pages/admin_dashboard_page.dart, package:bitwise_academy/features/admin/presentation/pages/admin_upload_skin_page.dart, package:bitwise_academy/features/admin/presentation/pages/create_exam_page.dart, package:bitwise_academy/features/admin/presentation/pages/create_questions_page.dart, package:bitwise_academy/features/admin/presentation/pages/exam_management_page.dart, package:bitwise_academy/features/auth/presentation/pages/login_page.dart (+25 more)

### Community 7 - "Exam Taking & Leaderboard UI"
Cohesion: 0.06
Nodes (32): package:cached_network_image/cached_network_image.dart, AppBar, build, _buildAppBar, _buildOption, CircularProgressIndicator, dispose, ExamTakingPage (+24 more)

### Community 8 - "Quest Repository & BLoC"
Cohesion: 0.06
Nodes (31): package:bitwise_academy/shared/models/quest_model.dart, guardedStream, guardedTask, _mapDocToQuest, QuestModel, QuestRepository, AcknowledgeQuestXpAward, _ActiveQuestsError (+23 more)

### Community 9 - "Analytics & Dashboard Cubits"
Cohesion: 0.07
Nodes (28): package:bitwise_academy/features/exam_library/data/repositories/attempt_repository.dart, package:bitwise_academy/features/exam_library/data/repositories/exam_repository.dart, package:bitwise_academy/shared/services/user_repository.dart, package:flutter_bloc/flutter_bloc.dart, AdminStatsCubit, AdminStatsState, copyWith, Failure (+20 more)

### Community 10 - "Auth BLoC & State"
Cohesion: 0.07
Nodes (26): AuthAuthenticated, AuthBloc, AuthCheckRequested, AuthCreateAccountRequested, AuthError, AuthEvent, AuthInitial, AuthLoading (+18 more)

### Community 11 - "Question Creation UI"
Cohesion: 0.08
Nodes (24): _addQuestion, AnimatedContainer, build, _buildAddedQuestionCard, _buildOptionInput, _buildPreviewCard, Center, _clearForm (+16 more)

### Community 12 - "Data Models & Entities"
Cohesion: 0.09
Nodes (19): package:cloud_firestore/cloud_firestore.dart, package:equatable/equatable.dart, SkinModel, AttemptModel, copyWith, fromString, copyWith, ExamModel (+11 more)

### Community 13 - "Pixel UI Components"
Cohesion: 0.08
Nodes (21): build, Container, paint, PixelContainer, _PixelContainerPainter, shouldRepaint, build, _CrtPainter (+13 more)

### Community 14 - "Repository Layer & Error Handling"
Cohesion: 0.12
Nodes (15): build, Center, _colorForTier, CreateExamPage, _CreateExamPageState, dispose, Expanded, Failure (+7 more)

### Community 15 - "Injection & DI Container"
Cohesion: 0.15
Nodes (13): package:bitwise_academy/core/errors/app_exception.dart, package:bitwise_academy/core/errors/result.dart, package:bitwise_academy/shared/models/user_entity.dart, AuthRepository, AuthResult, _mapDocToUser, UserEntity, UserProgressRepository (+5 more)

### Community 16 - "Store Cubit & Avatar UI"
Cohesion: 0.14
Nodes (13): package:image_picker/image_picker.dart, AdminUploadSkinPage, _AdminUploadSkinPageState, build, Center, dispose, Failure, Icon (+5 more)

### Community 17 - "Leaderboard BLoC"
Cohesion: 0.14
Nodes (13): package:bitwise_academy/core/widgets/pixel_input.dart, build, Dialog, dispose, _onRecover, paint, _PixelDialog, _PixelGridPainter (+5 more)

### Community 18 - "Admin Dashboard"
Cohesion: 0.19
Nodes (10): package:bitwise_academy/core/constants/app_colors.dart, package:bitwise_academy/core/constants/app_spacing.dart, package:bitwise_academy/core/constants/app_typography.dart, build, MouseRegion, PixelCard, _PixelCardState, build (+2 more)

### Community 19 - "Exam BLoC States"
Cohesion: 0.17
Nodes (11): package:bitwise_academy/core/widgets/latex_text.dart, build, _buildExplanationCard, _buildOptionTile, _buildQuestionCard, Column, Container, GestureDetector (+3 more)

### Community 20 - "Result Pattern & Failures"
Cohesion: 0.17
Nodes (11): package:bitwise_academy/core/constants/app_constants.dart, AuthRepositoryImpl, AuthResult, _dualWrite, _fetchPublicUser, _generateRecoveryKey, guardedTask, _hashString (+3 more)

### Community 21 - "Auth UI (Login / Register)"
Cohesion: 0.17
Nodes (11): package:bitwise_academy/features/store/data/repositories/store_repository.dart, package:bitwise_academy/shared/services/user_progress_repository.dart, copyWith, Failure, loadSkins, StoreCubit, StoreError, StoreInitial (+3 more)

### Community 22 - "User Progress Repository"
Cohesion: 0.17
Nodes (11): package:bitwise_academy/core/services/auth_service.dart, package:bitwise_academy/features/admin/presentation/cubit/admin_stats_cubit.dart, package:bitwise_academy/features/auth/data/datasources/auth_remote_datasource.dart, package:bitwise_academy/features/auth/data/repositories/auth_repository_impl.dart, package:bitwise_academy/features/dashboard/presentation/cubit/dashboard_cubit.dart, package:bitwise_academy/features/exam_library/data/services/mock_test_service.dart, package:bitwise_academy/features/leaderboard/presentation/bloc/leaderboard_bloc.dart, package:bitwise_academy/features/quest/data/repositories/quest_repository.dart (+3 more)

### Community 23 - "Attempt Repository"
Cohesion: 0.18
Nodes (10): package:bitwise_academy/core/widgets/hp_bar.dart, package:bitwise_academy/core/widgets/pixel_button.dart, AdminDashboardPage, build, _buildActivityItem, _buildStatBox, Container, HpBar (+2 more)

### Community 24 - "Skin & Store Models"
Cohesion: 0.18
Nodes (10): dart:convert, package:crypto/crypto.dart, package:firebase_auth/firebase_auth.dart, package:google_sign_in/google_sign_in.dart, package:sign_in_with_apple/sign_in_with_apple.dart, AuthException, AuthRemoteDataSource, _generateNonce (+2 more)

### Community 25 - "Question Model & Parsing"
Cohesion: 0.2
Nodes (9): package:flutter_math_fork/flutter_math.dart, build, ConstrainedBox, containsLatex, LatexText, LayoutBuilder, Text, _TextSegment (+1 more)

### Community 26 - "App Typography & Theming"
Cohesion: 0.2
Nodes (9): AppException, AuthException, FirestoreException, NetworkException, NotFoundException, PermissionException, StorageException, toString (+1 more)

### Community 27 - "Widget Utilities"
Cohesion: 0.22
Nodes (8): build, GestureDetector, _handleTapCancel, _handleTapDown, _handleTapUp, PixelButton, _PixelButtonState, SizedBox

### Community 28 - "Latex & Rich Text"
Cohesion: 0.29
Nodes (6): package:bitwise_academy/app.dart, package:bitwise_academy/core/di/injection.dart, package:bitwise_academy/firebase_options.dart, package:firebase_crashlytics/firebase_crashlytics.dart, package:firebase_storage/firebase_storage.dart, configureDependencies

### Community 29 - "Pixel Button & Inputs"
Cohesion: 0.29
Nodes (5): package:bitwise_academy/core/services/feature_flag_service.dart, package:flutter/material.dart, package:google_fonts/google_fonts.dart, build, FeatureToggle

### Community 30 - "Celebration Overlay"
Cohesion: 0.29
Nodes (6): build, Container, Expanded, HpBar, SizedBox, Stack

### Community 31 - "Firebase Options"
Cohesion: 0.33
Nodes (5): Failure, _resolveMessage, Result, Success, toString

### Community 32 - "Admin Upload Skin"
Cohesion: 0.33
Nodes (5): package:bitwise_academy/core/widgets/pixel_container.dart, build, Column, PixelProgressBar, Stack

### Community 33 - "Quest Celebration Logic"
Cohesion: 0.33
Nodes (5): package:bitwise_academy/core/utils/logger.dart, package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart, AuthService, Failure, Success

### Community 34 - "Logger & Utilities"
Cohesion: 0.4
Nodes (4): build, _getStyle, PixelTypography, Text

### Community 35 - "Feature Toggle Widget"
Cohesion: 0.4
Nodes (4): build, PlaceholderPage, Scaffold, SizedBox

## Knowledge Gaps
- **586 isolated node(s):** `DefaultFirebaseOptions`, `UnsupportedError`, `configureDependencies`, `package:bitwise_academy/app.dart`, `package:bitwise_academy/firebase_options.dart` (+581 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Pixel Button & Inputs` to `App Shell & Routing`, `Navigation & UI Shell`, `Dashboard & Config UI`, `Auth & Feature Flags`, `Firebase Interceptor & Store`, `Admin & Router Config`, `Exam Taking & Leaderboard UI`, `Question Creation UI`, `Pixel UI Components`, `Repository Layer & Error Handling`, `Store Cubit & Avatar UI`, `Leaderboard BLoC`, `Admin Dashboard`, `Exam BLoC States`, `Attempt Repository`, `Question Model & Parsing`, `Widget Utilities`, `Latex & Rich Text`, `Celebration Overlay`, `Admin Upload Skin`, `Logger & Utilities`, `Feature Toggle Widget`?**
  _High betweenness centrality (0.176) - this node is a cross-community bridge._
- **Why does `package:bitwise_academy/core/errors/result.dart` connect `Injection & DI Container` to `App Shell & Routing`, `Quest Celebration Logic`, `Exam & Mock Test Layer`, `Firebase Interceptor & Store`, `Quest Repository & BLoC`, `Analytics & Dashboard Cubits`, `Auth BLoC & State`, `Question Creation UI`, `Repository Layer & Error Handling`, `Store Cubit & Avatar UI`, `Result Pattern & Failures`, `Auth UI (Login / Register)`, `App Typography & Theming`?**
  _High betweenness centrality (0.175) - this node is a cross-community bridge._
- **Why does `package:flutter_bloc/flutter_bloc.dart` connect `Analytics & Dashboard Cubits` to `App Shell & Routing`, `Exam & Mock Test Layer`, `Navigation & UI Shell`, `Dashboard & Config UI`, `Auth & Feature Flags`, `Firebase Interceptor & Store`, `Admin & Router Config`, `Exam Taking & Leaderboard UI`, `Quest Repository & BLoC`, `Auth BLoC & State`, `Pixel UI Components`, `Leaderboard BLoC`, `Auth UI (Login / Register)`, `Attempt Repository`?**
  _High betweenness centrality (0.142) - this node is a cross-community bridge._
- **What connects `DefaultFirebaseOptions`, `UnsupportedError`, `configureDependencies` to the rest of the system?**
  _586 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App Shell & Routing` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Exam & Mock Test Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Navigation & UI Shell` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._