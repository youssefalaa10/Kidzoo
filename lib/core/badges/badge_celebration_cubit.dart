import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/badges/badge_celebration_state.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_service.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';

/// Holds the badge pop-up queue for the whole app.
///
/// Lives above the navigator, so a badge earned on a game screen still gets
/// celebrated when that screen pops itself on completion — which several of
/// them do.
class BadgeCelebrationCubit extends Cubit<BadgeCelebrationState> {
  BadgeCelebrationCubit({required BadgeService badgeService})
      : super(const BadgeCelebrationState()) {
    _subscription = badgeService.earnedBadgeStream.listen(enqueueBadges);
  }

  late final StreamSubscription<List<BadgeDefinition>> _subscription;
  Timer? _openingDelay;

  /// Queues a batch, skipping anything already waiting.
  ///
  /// The first badge of a quiet queue is held back briefly so the game's own
  /// win sound and star reveal land first: a badge should read as a
  /// consequence of finishing, not as an interruption of it.
  void enqueueBadges(List<BadgeDefinition> badges) {
    if (badges.isEmpty || isClosed) {
      return;
    }
    final Set<String> queued =
        state.pending.map((BadgeDefinition b) => b.badgeId).toSet();
    final List<BadgeDefinition> additions = badges
        .where((BadgeDefinition b) => !queued.contains(b.badgeId))
        .toList(growable: false);
    if (additions.isEmpty) {
      return;
    }
    if (state.pending.isNotEmpty) {
      emit(BadgeCelebrationState(
        pending: <BadgeDefinition>[...state.pending, ...additions],
      ));
      return;
    }
    _openingDelay?.cancel();
    _openingDelay = Timer(KidUi.celebrate, () {
      if (isClosed) {
        return;
      }
      emit(BadgeCelebrationState(
        pending: <BadgeDefinition>[...state.pending, ...additions],
      ));
    });
  }

  /// Drops the badge being shown and moves to the next, if any.
  void dismissCurrentBadge() {
    if (state.pending.isEmpty || isClosed) {
      return;
    }
    emit(BadgeCelebrationState(
      pending: state.pending.skip(1).toList(growable: false),
    ));
  }

  void clearQueue() {
    _openingDelay?.cancel();
    if (!isClosed) {
      emit(const BadgeCelebrationState());
    }
  }

  @override
  Future<void> close() {
    _openingDelay?.cancel();
    _subscription.cancel();
    return super.close();
  }
}
