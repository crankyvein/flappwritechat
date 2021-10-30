import 'package:appwrite/models.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flappwritechat/res/constants.dart';
import 'package:flappwritechat/models/channel.dart';

class ApiService {
  late Database db;
  late Account account;
  late Realtime realtime;
  static ApiService? _instance;
  final Client client = Client();

  ApiService._internal() {
    client
        .setEndpoint(AppConstants.endpoint)
        .setProject(AppConstants.projectId);
    account = Account(client);
    db = Database(client);
    realtime = Realtime(client);
  }

  static ApiService get instance {
    if (_instance == null) {
      _instance = ApiService._internal();
    }
    return _instance!;
  }

  Future<bool> signup(
      {required String name,
      required String email,
      required String password}) async {
    try {
      await account.create(name: name, email: email, password: password);
      return true;
    } on AppwriteException catch (e) {
      print(e.message);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      await account.createSession(email: email, password: password);
      return true;
    } on AppwriteException catch (e) {
      print(e.message);
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await account.deleteSessions();
      return true;
    } on AppwriteException catch (e) {
      print(e.message);
      return false;
    }
  }

  Future<User?> getUser() async {
    try {
      return await account.get();
    } on AppwriteException catch (e) {
      print(e.message);
      return null;
    }
  }

  Future<Channel?> addChannel(String title) async {
    try {
      final document = await db.createDocument(
        collectionId: AppConstants.channelsCollection,
        data: {
          "title": title,
        },
        read: ['role:member'],
        write: ['role:member'],
      );
      return document.convertTo<Channel>(
          (data) => Channel.fromMap(Map<String, dynamic>.from(data)));
    } on AppwriteException catch (e) {
      print(e.message);
      return null;
    }
  }

  RealtimeSubscription subscribe(List<String> channel) {
    return realtime.subscribe(channel);
  }

  addMessage(
      {required Map<String, dynamic> data, required String channelId}) async {
    try {
      await db.createDocument(
        collectionId: AppConstants.messagesCollection,
        data: data,
        read: ['role:member', "*"],
        write: ['user:${data["senderId"]}'],
        parentDocument: channelId,
        parentProperty: 'messages',
        parentPropertyType: 'append',
      );
    } on AppwriteException catch (e) {
      print(e.message);
    }
  }

  Future<List<Channel>> getChannels() async {
    try {
      final docList =
          await db.listDocuments(collectionId: AppConstants.channelsCollection);
      return docList.convertTo<Channel>(
          (data) => Channel.fromMap(Map<String, dynamic>.from(data)));
    } on AppwriteException catch (e) {
      print(e.message);
      return [];
    }
  }

  Future<void> deleteChannel(Channel channel) async {
    try {
      await db.deleteDocument(
          collectionId: AppConstants.channelsCollection,
          documentId: channel.id);
    } on AppwriteException catch (e) {
      print(e.message);
    }
  }
}
