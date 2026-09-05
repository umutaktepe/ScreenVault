/// Represents a TV Time friend and activity item
class FriendModel {
  final String friendId;
  final String name;
  final String? avatarUrl;
  final double affinity;
  final DateTime? addedAt;

  const FriendModel({
    required this.friendId,
    required this.name,
    this.avatarUrl,
    this.affinity = 0.0,
    this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'friend_id': friendId,
      'name': name,
      'avatar_url': avatarUrl,
      'affinity': affinity,
      'added_at': addedAt?.toIso8601String(),
    };
  }

  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      friendId: map['friend_id'] as String? ?? '',
      name: map['name'] as String? ?? 'TV Time Friend',
      avatarUrl: map['avatar_url'] as String?,
      affinity: (map['affinity'] as num?)?.toDouble() ?? 0.0,
      addedAt: map['added_at'] != null ? DateTime.tryParse(map['added_at'] as String) : null,
    );
  }
}

class CommunityActivityItem {
  final String id;
  final String userName;
  final String? userAvatar;
  final String actionType; // 'watched', 'rated', 'commented'
  final String showOrMovieTitle;
  final String? episodeCode; // S04 · E09
  final String? comment;
  final bool isSpoiler;
  final double? rating;
  final String emotion; // 🤯, 😢, 😂, 🔥, 😡
  final DateTime timestamp;
  final int likesCount;

  const CommunityActivityItem({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.actionType,
    required this.showOrMovieTitle,
    this.episodeCode,
    this.comment,
    this.isSpoiler = false,
    this.rating,
    this.emotion = '🔥',
    required this.timestamp,
    this.likesCount = 0,
  });
}
