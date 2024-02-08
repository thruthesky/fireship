import 'package:fireship/fireship.dart';

class Path {
  Path._();

  /// User
  static const String users = Folder.users;
  static const String userLikes = Folder.userLikes;
  static String like(String a, String b) => '$userLikes/$a/$b';
  static const String userProfilePhotos = Folder.userProfilePhotos;
  static const String userWhoIlike = Folder.userWhoIlike;

  /// Forum
  static const String posts = Folder.posts;
  static const String postSubscriptions = Folder.postSubscriptions;
  static const String postSummaries = Folder.postSummaries;
  static const String postAllSummaries = Folder.postAllSummaries;

  /// Chat
  static const String chatMessages = Folder.chatMessages;
  static String chatRoomUsersAt(roomId, uid) =>
      '${Folder.chatRooms}/$roomId/${Field.users}/$uid';
  static String chatRoomName(roomId) =>
      '${Folder.chatRooms}/$roomId/${Field.name}';
  static String chatRoomIconUrl(roomId) =>
      '${Folder.chatRooms}/$roomId/${Field.iconUrl}';

  static const String joins = Folder.chatJoins;
  static String join(String myUid, String roomId) => '$joins/$myUid/$roomId';

  static String get myReports => '${Folder.reports}/$myUid';

  static String categorySubscription(String category) =>
      '${Folder.postSubscriptions}/$category/$myUid';
}
