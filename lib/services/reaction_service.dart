import 'package:supabase_flutter/supabase_flutter.dart';

enum ReactionType { like, love, haha, wow, sad, angry }

extension ReactionTypeX on ReactionType {
  String get value => name;
  String get emoji {
    switch (this) {
      case ReactionType.like:  return '👍';
      case ReactionType.love:  return '❤️';
      case ReactionType.haha:  return '😂';
      case ReactionType.wow:   return '😮';
      case ReactionType.sad:   return '😢';
      case ReactionType.angry: return '😡';
    }
  }

  static ReactionType fromString(String s) =>
      ReactionType.values.firstWhere((e) => e.name == s,
          orElse: () => ReactionType.like);
}

class PostReactionState {
  final Map<String, int> counts;
  final ReactionType? myReaction;

  const PostReactionState({required this.counts, required this.myReaction});

  int get totalCount => counts.values.fold(0, (a, b) => a + b);

  PostReactionState copyWith({
    Map<String, int>? counts,
    ReactionType? myReaction,
    bool clearMyReaction = false,
  }) {
    return PostReactionState(
      counts: counts ?? this.counts,
      myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
    );
  }
}

class ReactionService {
  final _client = Supabase.instance.client;

  Future<PostReactionState> fetchReactions(String postId) async {
    final userId = _client.auth.currentUser?.id;

    final rows = await _client
        .from('post_reactions')
        .select('reaction_type, user_id')
        .eq('post_id', postId);

    final counts = <String, int>{};
    ReactionType? myReaction;

    for (final row in rows as List) {
      final type = row['reaction_type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
      if (userId != null && row['user_id'] == userId) {
        myReaction = ReactionTypeX.fromString(type);
      }
    }

    return PostReactionState(counts: counts, myReaction: myReaction);
  }

  Future<PostReactionState> toggleReaction(
      String postId, ReactionType type) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final existing = await _client
        .from('post_reactions')
        .select('id, reaction_type')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('post_reactions').insert({
        'post_id':       postId,
        'user_id':       userId,
        'reaction_type': type.value,
      });
    } else {
      final existingType = existing['reaction_type'] as String;
      if (existingType == type.value) {
        await _client
            .from('post_reactions')
            .delete()
            .eq('id', existing['id'] as String);
      } else {
        await _client
            .from('post_reactions')
            .update({'reaction_type': type.value})
            .eq('id', existing['id'] as String);
      }
    }

    return fetchReactions(postId);
  }

  // Returns RealtimeChannel — caller must call .unsubscribe() on dispose.
  RealtimeChannel subscribeToReactions(
      String postId, void Function() onUpdate) {
    return _client
        .channel('reactions_$postId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'post_reactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'post_id',
        value: postId,
      ),
      callback: (_) => onUpdate(),
    )
        .subscribe();
  }
}