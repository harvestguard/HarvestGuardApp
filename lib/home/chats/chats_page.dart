import 'package:animated_list_plus/transitions.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/global.dart';
import 'package:harvest_guard/home/app_bar.dart';
import 'package:harvest_guard/services/chat.dart';
import 'package:harvest_guard/services/tools.dart';
import 'package:provider/provider.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({required this.navigatorKey, required super.key});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage>
    with AutomaticKeepAliveClientMixin<ChatsPage> {
  @override
  bool get wantKeepAlive => true;

  final List<SearchInfo> _searchInfos = [];
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child('users');
  late final String _currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _loadSearchChats() async {
    try {
      final DataSnapshot snapshot = await _usersRef.get();
      if (snapshot.value == null || snapshot.key == _currentUserUid) return;

      final users = snapshot.value! as Map<dynamic, dynamic>;

      final updatedSearchInfos = users.entries
          .where((entry) => entry.key != _currentUserUid)
          .map((entry) => SearchInfo(
                uid: entry.key,
                name: _formatUserName(entry.value),
                thumbProfileImage: entry.value['thumbProfileImage'],
              ))
          .toList();

      if (mounted) {
        setState(() => _searchInfos
          ..clear()
          ..addAll(updatedSearchInfos));
      }
    } catch (e) {
      debugPrint('Error loading search chats: $e');
    }
  }

  String _formatUserName(Map<dynamic, dynamic> userData) {
    return '${userData['firstName']} ${userData['middleName']} ${userData['lastName']}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Widget _buildNoMessageView(ThemeData theme) {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/no_messages.png',
              width: 150,
              height: 150,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 20),
            Text(
              'YOU HAVE NO MESSAGES',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'Start a new conversation by clicking the button below',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // handle new conversation button press
              },
              child: const Text('New Conversation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<ChatInfo> chats, ChatDatabase chatDatabase) {
    return SliverToBoxAdapter(
      child: ImplicitlyAnimatedList<ChatInfo>(
        items: chats,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        areItemsTheSame: (a, b) => a.uid == b.uid,
        itemBuilder: (context, animation, chatInfo, index) {
          return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            animation: animation,
            child: _ChatListItem(
              chatInfo: chatInfo,
              chatDatabase: chatDatabase,
              onTap: () => _navigateToChat(context, chatInfo.uid, chatDatabase),
            ),
          );
        },
      ),
    );
  }

  void _navigateToChat(
      BuildContext context, String chatUid, ChatDatabase chatDatabase) {
    Navigator.of(context).pushNamed(
      '/chat',
      arguments: {
        'chat': Chat(chat: chatDatabase.chatsMap, chatUid: chatUid),
        'from': context,
      },
    );
  }

  List<ChatInfo> _getSortedChats(ChatDatabase chatDatabase) {
    return chatDatabase.chatsMap.entries
        .where((entry) =>
            ChatInfo.fromMap(entry.key, entry.value).lastMessageTime.isNotEmpty)
        .map((entry) => ChatInfo.fromMap(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final chatDatabase = context.watch<ChatDatabase>();
    final sortedChats = _getSortedChats(chatDatabase);

    return RepaintBoundary(
      child: Scaffold(
        body: CustomScrollView(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          slivers: [
            const HomeAppBar(
              title: 'Chats',
              leftIcon: _DrawerButton(),
              rightIcon: _ProfileButton(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: SearchChatsHeaderDelegate(
                searchInfo: _searchInfos,
                databaseName: 'chatSearchHistory',
                barHintText: 'Search chats',
                cont: context,
                onTap: _loadSearchChats,
              ),
            ),
            sortedChats.isEmpty
                ? _buildNoMessageView(theme)
                : _buildChatList(sortedChats, chatDatabase),
          ],
        ),
      ),
    );
  }
}

class _DrawerButton extends StatelessWidget {
  const _DrawerButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(FluentIcons.list_24_filled),
      onPressed: () => scaffoldKey.currentState?.openDrawer(),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(FluentIcons.person_24_regular),
      onPressed: () {},
    );
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.chatInfo,
    required this.chatDatabase,
    required this.onTap,
  });

  final ChatInfo chatInfo;
  final ChatDatabase chatDatabase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(chatInfo.thumbProfileImage),
        radius: 25,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chatInfo.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(
            parseDate(chatInfo.lastMessageTime),
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 13.0,
            ),
          ),
        ],
      ),
      subtitle: Text(
        chatInfo.lastMessage.replaceAll('\n', ' '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
