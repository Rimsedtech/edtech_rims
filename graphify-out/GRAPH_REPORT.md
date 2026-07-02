# Graph Report - lib  (2026-05-14)

## Corpus Check
- 75 files · ~37,741 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 737 nodes · 1055 edges · 45 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cfbca03f`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 33 edges
2. `package:bitwise_academy/core/errors/result.dart` - 31 edges
3. `package:bitwise_academy/core/constants/app_typography.dart` - 27 edges
4. `package:bitwise_academy/core/constants/app_colors.dart` - 23 edges
5. `package:bitwise_academy/core/constants/app_spacing.dart` - 22 edges
6. `package:flutter_bloc/flutter_bloc.dart` - 21 edges
7. `package:bitwise_academy/shared/models/user_entity.dart` - 16 edges
8. `package:cloud_firestore/cloud_firestore.dart` - 15 edges
9. `package:go_router/go_router.dart` - 15 edges
10. `package:equatable/equatable.dart` - 15 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities (47 total, 2 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (41): package:bitwise_academy/core/widgets/pixel_input.dart, package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart, package:bitwise_academy/features/auth/presentation/cubit/auth_form_cubit.dart, package:bitwise_academy/features/auth/presentation/cubit/auth_form_state.dart, package:flutter_bloc/flutter_bloc.dart, AdminStatsCubit, AdminStatsState, copyWith (+33 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (38): dart:convert, package:bitwise_academy/core/constants/app_constants.dart, package:bitwise_academy/core/services/auth_service.dart, package:bitwise_academy/core/utils/logger.dart, package:bitwise_academy/features/auth/data/datasources/auth_remote_datasource.dart, package:bitwise_academy/features/auth/data/repositories/auth_repository_impl.dart, package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart, package:bitwise_academy/features/dashboard/presentation/cubit/dashboard_cubit.dart (+30 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (38): package:back_button_interceptor/back_button_interceptor.dart, build, _currentIndex, dispose, Expanded, _getOriginalIndex, _handleFinalBackPress, initState (+30 more)

### Community 3 - "Community 3"
Cohesion: 0.06
Nodes (32): package:bitwise_academy/app.dart, package:bitwise_academy/core/di/injection.dart, package:bitwise_academy/firebase_options.dart, package:firebase_core/firebase_core.dart, package:firebase_crashlytics/firebase_crashlytics.dart, package:firebase_storage/firebase_storage.dart, package:flutter/foundation.dart, package:logger/logger.dart (+24 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (33): package:bitwise_academy/features/quest/domain/repositories/quest_repository.dart, package:bitwise_academy/shared/models/quest_model.dart, guardedStream, guardedTask, _mapDocToQuest, QuestModel, QuestRepositoryImpl, QuestRepository (+25 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (27): package:cloud_firestore/cloud_firestore.dart, package:equatable/equatable.dart, AuthRepository, AuthResult, AuthFormError, AuthFormInitial, AuthFormLoading, AuthFormPasswordResetSent (+19 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (31): package:bitwise_academy/core/widgets/pixel_card.dart, package:bitwise_academy/features/leaderboard/presentation/bloc/leaderboard_bloc.dart, package:cached_network_image/cached_network_image.dart, build, _buildSectionLabel, Center, Container, Function (+23 more)

### Community 7 - "Community 7"
Cohesion: 0.06
Nodes (30): package:bitwise_academy/core/widgets/feature_toggle.dart, package:bitwise_academy/core/widgets/shell_scaffold.dart, package:bitwise_academy/features/admin/presentation/pages/admin_dashboard_page.dart, package:bitwise_academy/features/admin/presentation/pages/admin_upload_skin_page.dart, package:bitwise_academy/features/admin/presentation/pages/create_exam_page.dart, package:bitwise_academy/features/admin/presentation/pages/create_questions_page.dart, package:bitwise_academy/features/admin/presentation/pages/exam_management_page.dart, package:bitwise_academy/features/auth/presentation/pages/login_page.dart (+22 more)

### Community 8 - "Community 8"
Cohesion: 0.07
Nodes (28): package:image_picker/image_picker.dart, AdminUploadSkinPage, _AdminUploadSkinPageState, build, Center, dispose, Failure, Icon (+20 more)

### Community 9 - "Community 9"
Cohesion: 0.07
Nodes (28): build, _buildBrandTitle, _buildCardHeader, _buildDivider, _buildFooterLinks, _buildLoginCard, Column, Container (+20 more)

### Community 10 - "Community 10"
Cohesion: 0.07
Nodes (26): package:bitwise_academy/features/quest/presentation/bloc/quest_bloc.dart, package:confetti/confetti.dart, package:flutter_animate/flutter_animate.dart, package:flutter/services.dart, build, dispose, Icon, initState (+18 more)

### Community 11 - "Community 11"
Cohesion: 0.08
Nodes (24): AuthAuthenticated, AuthBloc, AuthCheckRequested, AuthError, AuthEvent, AuthFormOperationCompleted, AuthFormOperationStarted, AuthInitial (+16 more)

### Community 12 - "Community 12"
Cohesion: 0.08
Nodes (24): _addQuestion, AnimatedContainer, build, _buildAddedQuestionCard, _buildOptionInput, _buildPreviewCard, Center, _clearForm (+16 more)

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (24): package:bitwise_academy/core/widgets/mock_test_config_sheet.dart, AuthSignOutRequested, build, _buildAppBar, _buildAvatarImage, _buildBottomSection, _buildHeroSection, _buildQuestItem (+16 more)

### Community 14 - "Community 14"
Cohesion: 0.1
Nodes (20): AnswerSelected, AttemptBloc, AttemptCompleted, AttemptEvent, AttemptFailure, AttemptInitial, AttemptInProgress, AttemptLoadInProgress (+12 more)

### Community 15 - "Community 15"
Cohesion: 0.11
Nodes (17): AppBar, build, _buildAppBar, _buildOption, CircularProgressIndicator, dispose, ExamTakingPage, _ExamTakingPageState (+9 more)

### Community 16 - "Community 16"
Cohesion: 0.19
Nodes (10): package:bitwise_academy/core/constants/app_colors.dart, package:bitwise_academy/core/constants/app_spacing.dart, package:bitwise_academy/core/constants/app_typography.dart, build, Column, PixelInput, build, PlaceholderPage (+2 more)

### Community 17 - "Community 17"
Cohesion: 0.15
Nodes (12): build, _buildResultsUI, dispose, Divider, ExamResultsPage, _ExamResultsPageState, Failure, initState (+4 more)

### Community 18 - "Community 18"
Cohesion: 0.15
Nodes (12): package:bitwise_academy/core/widgets/hp_bar.dart, package:bitwise_academy/core/widgets/pixel_button.dart, package:bitwise_academy/features/admin/presentation/cubit/admin_stats_cubit.dart, package:go_router/go_router.dart, AdminDashboardPage, build, _buildActivityItem, _buildStatBox (+4 more)

### Community 19 - "Community 19"
Cohesion: 0.15
Nodes (12): package:bitwise_academy/core/router/app_router.dart, package:bitwise_academy/core/theme/app_theme.dart, package:bitwise_academy/core/widgets/quest_celebration_overlay.dart, package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart, build, dispose, initState, MultiBlocProvider (+4 more)

### Community 20 - "Community 20"
Cohesion: 0.17
Nodes (11): package:bitwise_academy/core/widgets/latex_text.dart, build, _buildExplanationCard, _buildOptionTile, _buildQuestionCard, Column, Container, GestureDetector (+3 more)

### Community 21 - "Community 21"
Cohesion: 0.18
Nodes (10): package:bitwise_academy/features/exam_library/domain/repositories/exam_repository.dart, ExamRepositoryImpl, Failure, guardedStream, guardedTask, _mapDocToExam, _mapDocToQuestion, NotFoundException (+2 more)

### Community 22 - "Community 22"
Cohesion: 0.18
Nodes (10): package:bitwise_academy/features/store/data/repositories/store_repository.dart, copyWith, Failure, loadSkins, StoreCubit, StoreError, StoreInitial, StoreLoaded (+2 more)

### Community 23 - "Community 23"
Cohesion: 0.18
Nodes (10): Failure, FetchLeaderboardRequested, LeaderboardBloc, LeaderboardEvent, LeaderboardInitial, LeaderboardLoadFailure, LeaderboardLoadInProgress, LeaderboardLoadSuccess (+2 more)

### Community 24 - "Community 24"
Cohesion: 0.2
Nodes (9): package:flutter_math_fork/flutter_math.dart, build, ConstrainedBox, containsLatex, LatexText, LayoutBuilder, Text, _TextSegment (+1 more)

### Community 25 - "Community 25"
Cohesion: 0.2
Nodes (8): package:bitwise_academy/core/utils/firebase_interceptor.dart, package:bitwise_academy/features/exam_library/domain/repositories/attempt_repository.dart, package:bitwise_academy/shared/models/attempt_model.dart, AttemptModel, AttemptRepositoryImpl, guardedTask, _mapDocToAttempt, AttemptRepository

### Community 26 - "Community 26"
Cohesion: 0.2
Nodes (9): AppException, AuthException, FirestoreException, NetworkException, NotFoundException, PermissionException, StorageException, toString (+1 more)

### Community 27 - "Community 27"
Cohesion: 0.2
Nodes (9): DashboardCubit, DashboardError, DashboardInitial, DashboardLoaded, DashboardLoading, DashboardState, Failure, loadDashboard (+1 more)

### Community 28 - "Community 28"
Cohesion: 0.22
Nodes (8): build, GestureDetector, _handleTapCancel, _handleTapDown, _handleTapUp, PixelButton, _PixelButtonState, SizedBox

### Community 29 - "Community 29"
Cohesion: 0.29
Nodes (5): package:bitwise_academy/core/services/feature_flag_service.dart, package:flutter/material.dart, package:google_fonts/google_fonts.dart, build, FeatureToggle

### Community 30 - "Community 30"
Cohesion: 0.29
Nodes (6): build, Container, Expanded, HpBar, SizedBox, Stack

### Community 31 - "Community 31"
Cohesion: 0.29
Nodes (6): build, Container, paint, PixelContainer, _PixelContainerPainter, shouldRepaint

### Community 32 - "Community 32"
Cohesion: 0.29
Nodes (6): package:bitwise_academy/shared/domain/repositories/user_repository.dart, Duration, _mapDocToUser, UserEntity, UserRepositoryImpl, _watchUserWithRetry

### Community 33 - "Community 33"
Cohesion: 0.33
Nodes (5): package:bitwise_academy/core/widgets/pixel_container.dart, build, Column, PixelProgressBar, Stack

### Community 34 - "Community 34"
Cohesion: 0.33
Nodes (5): Failure, _resolveMessage, Result, Success, toString

### Community 35 - "Community 35"
Cohesion: 0.33
Nodes (5): dart:math, Failure, _mapDocToQuestion, MockTestService, NotFoundException

### Community 36 - "Community 36"
Cohesion: 0.33
Nodes (5): package:bitwise_academy/core/errors/app_exception.dart, package:bitwise_academy/shared/domain/repositories/user_progress_repository.dart, _mapDocToUser, UserEntity, UserProgressRepositoryImpl

### Community 37 - "Community 37"
Cohesion: 0.4
Nodes (4): package:bitwise_academy/core/errors/result.dart, package:bitwise_academy/shared/models/user_entity.dart, UserProgressRepository, UserRepository

### Community 38 - "Community 38"
Cohesion: 0.33
Nodes (5): dart:async, FirebaseGuardedExecution, streamAction, timeout, TimeoutException

### Community 39 - "Community 39"
Cohesion: 0.33
Nodes (5): package:bitwise_academy/features/store/data/models/skin_model.dart, package:injectable/injectable.dart, guardedStream, guardedTask, StoreRepository

### Community 40 - "Community 40"
Cohesion: 0.4
Nodes (4): build, _getStyle, PixelTypography, Text

### Community 41 - "Community 41"
Cohesion: 0.4
Nodes (4): build, MouseRegion, PixelCard, _PixelCardState

### Community 42 - "Community 42"
Cohesion: 0.4
Nodes (4): dart:io, package:bitwise_academy/shared/models/exam_model.dart, package:bitwise_academy/shared/models/question_model.dart, ExamRepository

## Knowledge Gaps
- **601 isolated node(s):** `DefaultFirebaseOptions`, `UnsupportedError`, `configureDependencies`, `package:bitwise_academy/app.dart`, `package:bitwise_academy/firebase_options.dart` (+596 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:bitwise_academy/core/errors/result.dart` connect `Community 37` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 8`, `Community 11`, `Community 12`, `Community 14`, `Community 17`, `Community 21`, `Community 22`, `Community 23`, `Community 25`, `Community 26`, `Community 27`, `Community 32`, `Community 35`, `Community 36`, `Community 38`, `Community 39`, `Community 42`?**
  _High betweenness centrality (0.187) - this node is a cross-community bridge._
- **Why does `package:flutter/material.dart` connect `Community 29` to `Community 0`, `Community 2`, `Community 3`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 12`, `Community 13`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 19`, `Community 20`, `Community 24`, `Community 28`, `Community 30`, `Community 31`, `Community 33`, `Community 40`, `Community 41`?**
  _High betweenness centrality (0.167) - this node is a cross-community bridge._
- **Why does `package:flutter_bloc/flutter_bloc.dart` connect `Community 0` to `Community 2`, `Community 4`, `Community 6`, `Community 7`, `Community 9`, `Community 10`, `Community 11`, `Community 13`, `Community 14`, `Community 15`, `Community 17`, `Community 18`, `Community 19`, `Community 22`, `Community 23`, `Community 27`?**
  _High betweenness centrality (0.137) - this node is a cross-community bridge._
- **What connects `DefaultFirebaseOptions`, `UnsupportedError`, `configureDependencies` to the rest of the system?**
  _601 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._