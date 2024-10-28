import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/home/chats/chats_page.dart';
import 'package:harvest_guard/home/products/product_page.dart';
import 'package:harvest_guard/services/chat.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.title,
    required this.leftIcon,
    required this.rightIcon,
  });
  final String title;
  final Widget leftIcon;
  final Widget rightIcon;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 100,
      pinned: true,
      flexibleSpace: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            leftIcon,
            const Spacer(),
            SizedBox(
              width: 200,
              child: FlexibleSpaceBar(
                expandedTitleScale: 1.75,
                titlePadding: const EdgeInsets.only(bottom: 5),
                title: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            const Spacer(),
            rightIcon,
          ],
        ),
      ),
    );
  }
}

class ChatInfo {
  ChatInfo(
      {required this.uid,
      required this.name,
      required this.thumbProfileImage,
      required this.profileImage,
      required this.lastMessage,
      required this.lastMessageSender,
      required this.lastMessageTime});
  final String uid;
  final String name;
  final String thumbProfileImage;
  final String profileImage;
  final String lastMessage;
  final String lastMessageSender;
  final String lastMessageTime;

  final Map<String, dynamic> _messages = <String, dynamic>{};

  ImageProvider get image => NetworkImage(thumbProfileImage);

  static ChatInfo fromQuery(QueryDocumentSnapshot query) {
    bool isGroup = query['members'].length > 2;
    String receiver = '';
    String name = '';
    String thumbProfileImage = '';
    String profileImage = '';

    if (isGroup) {
      name = query['info']['name'] ?? query['members'].keys.toList().join(', ');
    } else {
      for (var member in query['info']['members']) {
        if (member != FirebaseAuth.instance.currentUser!.uid) {
          receiver = member;
          break;
        }
      }
      name =
          '${query['members'][receiver]['name']['firstName']} ${query['members'][receiver]['name']['middleName']} ${query['members'][receiver]['name']['lastName']}';
      thumbProfileImage = query['members'][receiver]['thumbProfileImage'];
      profileImage = query['members'][receiver]['profileImage'];
    }



    return ChatInfo(
      uid: query.id,
      name: name,
      thumbProfileImage: thumbProfileImage,
      profileImage: profileImage,
      lastMessage: query['info']['lastMessage'],
      lastMessageSender: query['info']['lastMessageSender'],
      lastMessageTime: query['info']['lastMessageTime'],
    );
  }

  static ChatInfo fromMap(String key, Map<String, dynamic> map) {
    bool isGroup = map['members'].length > 2;
    String receiver = '';
    String name = '';
    String thumbProfileImage = '';
    String profileImage = '';
    String lastMessage = map['info']['lastMessage'];
    String lastMessageSender = map['info']['lastMessageSender'];
    String lastMessageTime = map['info']['lastMessageTime'];

    if (isGroup) {
      name = map['info']['name'] ?? map['members'].keys.toList().join(', ');
    } else {
      for (var member in map['info']['members']) {
        if (member != FirebaseAuth.instance.currentUser!.uid) {
          receiver = member;
          break;
        }
      }

      var user = map['members'][receiver];

      name =
          '${user['name']['firstName']} ${user['name']['middleName']} ${user['name']['lastName']}';
      thumbProfileImage = user['thumbProfileImage'];
      profileImage = user['profileImage'];
    }

    

    if (map['messages'].isNotEmpty) {
      lastMessage = map['messages'].values.last['message'];
      lastMessageSender = map['messages'].values.last['sender'];
      lastMessageTime = map['messages'].values.last['timestamp'];
    }

    // print('LastElement: $lastMessage $lastMessageSender $lastMessageTime');

    return ChatInfo(
      uid: key,
      name: name,
      thumbProfileImage: thumbProfileImage,
      profileImage: profileImage,
      lastMessage: lastMessage,
      lastMessageSender: lastMessageSender,
      lastMessageTime: lastMessageTime,
    );
  }
  
}

class SearchInfo {
  SearchInfo(
      {required this.uid, required this.name, required this.thumbProfileImage});
  final String uid;
  final String name;
  final String thumbProfileImage;

  ImageProvider get image => NetworkImage(thumbProfileImage);
}

class SearchListData extends StatefulWidget {
  SearchListData({
    super.key,
    required this.searchInfo,
    required this.databaseName,
    this.barHintText = 'Search',
    this.cont,
    this.onTap,
  });

  final List<SearchInfo> searchInfo;
  final List<SearchInfo> _searchInfoHistory = <SearchInfo>[];
  final String barHintText;
  final String? databaseName;
  final BuildContext? cont;
  final VoidCallback? onTap;

  @override
  State<SearchListData> createState() => _SearchChatsState();
}

class _SearchChatsState extends State<SearchListData> {
  String? selected;

  Future<Iterable<Widget>> getHistoryList(SearchController controller) async {
    // List<SearchInfo> searchInfoHistory = <SearchInfo>[];
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child(widget.databaseName!)
        .get()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        widget._searchInfoHistory.clear();
        Map.fromEntries(
                (snapshot.value! as Map<dynamic, dynamic>).entries.toList()
                  ..sort((a, b) =>
                      b.value['timestamp'].compareTo(a.value['timestamp'])))
            .forEach((key, value) {
          setState(() {
            widget._searchInfoHistory.add(
              SearchInfo(
                uid: key,
                name: value['name'],
                thumbProfileImage: value['thumbProfileImage'],
              ),
            );
          });
        });
      }
    });

    return widget._searchInfoHistory.map((info) => ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 6),
          leading: const Icon(Icons.history),
          title: Text(info.name),
          trailing: IconButton(
              icon: const Icon(FluentIcons.delete_24_filled),
              onPressed: () async {
                await FirebaseDatabase.instance
                    .ref()
                    .child('users')
                    .child(FirebaseAuth.instance.currentUser!.uid)
                    .child(widget.databaseName!)
                    .child(info.uid)
                    .remove();

                controller.notifyListeners();
              }),
          onTap: () async {
            controller.closeView(info.name);
            await handleSelection(info, widget._searchInfoHistory);

            // get the main page

            if (mounted) {
              var home = context.findAncestorWidgetOfExactType<ChatsPage>()!;
              Navigator.of(context).pushNamed(
                '/chat',
                arguments: {
                  'chat': Chat(
                    chat: Provider.of<ChatDatabase>(context, listen: false).chatsMap,
                    chatMembers: [
                      FirebaseAuth.instance.currentUser!.uid,
                      info.uid
                    ]),
                  'from': home,
                },
              );
            }
          },
        ));
  }

  Iterable<Widget> getSuggestions(
      SearchController controller, List<SearchInfo> infos) {
    final String input = controller.value.text;
    return infos
        .where((info) => info.name.toLowerCase().contains(input.toLowerCase()))
        .map((filteredInfo) => ListTile(
              contentPadding: const EdgeInsets.only(left: 16, right: 6),
              leading: CircleAvatar(backgroundImage: filteredInfo.image),
              title: Text(filteredInfo.name),
              onTap: () async {
                controller.closeView(filteredInfo.name);

                await handleSelection(filteredInfo, infos);

                if (mounted) {
                  var home =
                      context.findAncestorWidgetOfExactType<ChatsPage>()!;
                  Navigator.of(context).pushNamed(
                    '/chat',
                    arguments: {
                      'chat': Chat(
                        chat: Provider.of<ChatDatabase>(context, listen: false).chatsMap,
                        chatMembers: [
                          FirebaseAuth.instance.currentUser!.uid,
                          filteredInfo.uid
                        ]),
                      'from': home,
                    },
                  );
                }
              },
            ));
  }

  Future handleSelection(SearchInfo info, List<SearchInfo> infos) async {
    selected = info.name;
    //count the number of search history
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child(widget.databaseName!)
        .get()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        if (snapshot.children.length >= 5) {
          FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(FirebaseAuth.instance.currentUser!.uid)
              .child(widget.databaseName!)
              .child(infos.last.uid)
              .remove();
        }
      }
    });

    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child(widget.databaseName!)
        .child(info.uid)
        .set({
      'name': info.name,
      'thumbProfileImage': info.thumbProfileImage,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SearchAnchor.bar(
          onTap: widget.onTap!,
          // isFullScreen: false,
          barElevation: const WidgetStatePropertyAll<double>(1),
          barBackgroundColor: WidgetStatePropertyAll<Color>(
              Theme.of(context).colorScheme.onInverseSurface),
          barHintText: widget.barHintText,
          suggestionsBuilder: (context, controller) async {
            if (controller.text.isEmpty) {
              Iterable<Widget> historyList = await getHistoryList(controller);
              if (widget._searchInfoHistory.isNotEmpty) {
                return historyList;
              }
              return <Widget>[
                const SizedBox(height: 20),
                Center(
                  child: Text('No search history.',
                      style: TextStyle(color: Theme.of(context).hintColor)),
                )
              ];
            }
            return getSuggestions(controller, widget.searchInfo);
          },
        ),
        // const SizedBox(height: 20),
      ],
    );
  }
}

class SearchChatsHeaderDelegate extends SliverPersistentHeaderDelegate {
  SearchChatsHeaderDelegate(
      {required this.searchInfo,
      required this.databaseName,
      this.barHintText = 'Search',
      required this.cont,
      required this.onTap});
  final List<SearchInfo> searchInfo;
  final String barHintText;
  final BuildContext cont;
  final String databaseName;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
        child: SearchListData(
          searchInfo: searchInfo,
          barHintText: barHintText,
          cont: cont,
          onTap: onTap,
          databaseName: databaseName,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 90.0;

  @override
  double get minExtent => 90.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class SearchProductInfo {
  SearchProductInfo(
      {required this.adminUid,
      required this.itemUid,
      required this.name,
      required this.thumbProductImage});
  final String adminUid;
  final String itemUid;
  final String name;
  final String thumbProductImage;

  ImageProvider get image => NetworkImage(thumbProductImage);
}

class SearchListProductData extends StatefulWidget {
  SearchListProductData({
    super.key,
    required this.searchProductInfo,
    required this.databaseName,
    this.barHintText = 'Search',
    this.cont,
    this.onTap,
  });

  final List<SearchProductInfo> searchProductInfo;
  final List<SearchProductInfo> _searchProductInfoHistory =
      <SearchProductInfo>[];
  final String barHintText;
  final String? databaseName;
  final BuildContext? cont;
  final VoidCallback? onTap;

  @override
  State<SearchListProductData> createState() => _SearchProductsState();
}

class _SearchProductsState extends State<SearchListProductData> {
  String? selected;

  Future<Iterable<Widget>> getHistoryList(SearchController controller) async {
    // List<SearchInfo> searchInfoHistory = <SearchInfo>[];
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child(widget.databaseName!)
        .get()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        widget._searchProductInfoHistory.clear();
        Map.fromEntries(
                (snapshot.value! as Map<dynamic, dynamic>).entries.toList()
                  ..sort((a, b) =>
                      b.value['timestamp'].compareTo(a.value['timestamp'])))
            .forEach((key, value) {
          setState(() {
            widget._searchProductInfoHistory.add(
              SearchProductInfo(
                adminUid: value['adminUid'],
                itemUid: key,
                name: value['name'],
                thumbProductImage: value['thumbProductImage'],
              ),
            );
          });
        });
      }
    });

    return widget._searchProductInfoHistory.map((info) => ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 6),
          leading: const Icon(Icons.history),
          title: Text(info.name),
          trailing: IconButton(
              icon: const Icon(FluentIcons.delete_24_filled),
              onPressed: () async {
                await FirebaseDatabase.instance
                    .ref()
                    .child('users')
                    .child(FirebaseAuth.instance.currentUser!.uid)
                    .child(widget.databaseName!)
                    .child(info.itemUid)
                    .remove();

                controller.notifyListeners();
              }),
          onTap: () async {
            controller.closeView(info.name);
            await handleSelection(info, widget._searchProductInfoHistory);

            // get the main page
            if (mounted) {
              context.pushTransparentRoute(
                  ProductPage(adminId: info.adminUid, productId: info.itemUid));
            }
          },
        ));
  }

  Iterable<Widget> getSuggestions(
      SearchController controller, List<SearchProductInfo> infos) {
    final String input = controller.value.text;
    return infos
        .where((info) => info.name.toLowerCase().contains(input.toLowerCase()))
        .map((filteredInfo) => ListTile(
              contentPadding: const EdgeInsets.only(left: 16, right: 6),
              leading: CircleAvatar(backgroundImage: filteredInfo.image),
              title: Text(filteredInfo.name),
              onTap: () async {
                controller.closeView(filteredInfo.name);

                await handleSelection(filteredInfo, infos);

                if (mounted) {
                  context.pushTransparentRoute(ProductPage(
                      adminId: filteredInfo.adminUid,
                      productId: filteredInfo.itemUid));
                }
              },
            ));
  }

  Future handleSelection(
      SearchProductInfo info, List<SearchProductInfo> infos) async {
    selected = info.name;
    //count the number of search history
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child(widget.databaseName!)
        .get()
        .then((DataSnapshot snapshot) {
      if (snapshot.value != null) {
        if (snapshot.children.length >= 5) {
          FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(FirebaseAuth.instance.currentUser!.uid)
              .child(widget.databaseName!)
              .child(infos.last.itemUid)
              .remove();
        }
      }
    });

    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child(widget.databaseName!)
        .child(info.itemUid)
        .set({
      'name': info.name,
      'adminUid': info.adminUid,
      'thumbProductImage': info.thumbProductImage,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SearchAnchor.bar(
          onTap: widget.onTap!,
          // isFullScreen: false,
          barElevation: const WidgetStatePropertyAll<double>(1),
          barBackgroundColor: WidgetStatePropertyAll<Color>(
              Theme.of(context).colorScheme.onInverseSurface),
          barHintText: widget.barHintText,
          suggestionsBuilder: (context, controller) async {
            if (controller.text.isEmpty) {
              Iterable<Widget> historyList = await getHistoryList(controller);
              if (widget._searchProductInfoHistory.isNotEmpty) {
                return historyList;
              }
              return <Widget>[
                const SizedBox(height: 20),
                Center(
                  child: Text('No search history.',
                      style: TextStyle(color: Theme.of(context).hintColor)),
                )
              ];
            }
            return getSuggestions(controller, widget.searchProductInfo);
          },
        ),
        // const SizedBox(height: 20),
      ],
    );
  }
}

class SearchProductsHeaderDelegate extends SliverPersistentHeaderDelegate {
  SearchProductsHeaderDelegate(
      {required this.searchProductInfo,
      required this.databaseName,
      this.barHintText = 'Search',
      required this.cont,
      required this.onTap});
  final List<SearchProductInfo> searchProductInfo;
  final String barHintText;
  final BuildContext cont;
  final String databaseName;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
        child: SearchListProductData(
          searchProductInfo: searchProductInfo,
          barHintText: barHintText,
          cont: cont,
          onTap: onTap,
          databaseName: databaseName,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 90.0;

  @override
  double get minExtent => 90.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
