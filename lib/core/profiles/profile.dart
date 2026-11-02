class Profile {
  const Profile({required this.id, required this.nickname, required this.avatar});

  final int id;
  final String nickname;
  final String avatar;

  Profile copyWith({String? nickname, String? avatar}) =>
      Profile(id: id, nickname: nickname ?? this.nickname, avatar: avatar ?? this.avatar);
}
