import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/front_page.dart';
import 'package:harvest_guard/home/auctions/auctions_page.dart';
import 'package:harvest_guard/home/shipping/shipments_page.dart';
import 'package:provider/provider.dart';

import '../global.dart';
import 'chats/chats_page.dart';
import 'products/products_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

int _selectedIndex = 0;

class HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  @override
  bool get wantKeepAlive => true;

  final List<NavigationRailDestination> _destinationLarge = const [
    NavigationRailDestination(
      selectedIcon: Icon(FluentIcons.home_16_filled),
      icon: Icon(FluentIcons.home_16_regular),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      selectedIcon: Badge(
        label: Text("10"),
        child: Icon(FluentIcons.chat_16_filled),
      ),
      icon: Badge(
        label: Text("10"),
        child: Icon(FluentIcons.chat_16_regular),
      ),
      label: Text('Chats'),
    ),
    NavigationRailDestination(
      selectedIcon: Badge(
        label: Text("10"),
        child: Icon(FluentIcons.shopping_bag_16_filled),
      ),
      icon: Badge(
        label: Text("10"),
        child: Icon(FluentIcons.shopping_bag_16_regular),
      ),
      label: Text('Auctions'),
    ),
    NavigationRailDestination(
      selectedIcon: Icon(FluentIcons.vehicle_truck_profile_16_filled),
      icon: Icon(FluentIcons.vehicle_truck_profile_16_regular),
      label: Text('Shipments'),
    ),
  ];

  PageController _pageController =
      PageController(initialPage: _selectedIndex, keepPage: true);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        _selectedIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
      _pageController =
          PageController(initialPage: _selectedIndex, keepPage: true);
    });
  }

  GlobalKey<NavigatorState> _navigatorKey() {
    switch (_selectedIndex) {
      case 0:
        return navItemHome;
      case 1:
        return navItemChats;
      case 2:
        return navItemAuctions;
      case 3:
        return navItemShipments;
      default:
        return navItemHome;
    }
  }

  late String _name = '';
  late String _email = '';
  late String _profileImage = '';
  @override
  void initState() {
    notificationDatabase;

    FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser!.uid)
        .onValue
        .listen((event) {
      final user = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _name =
            '${user['firstName']} ${user['middleName']} ${user['lastName']}';
        _email = user['email'];
        _profileImage = user['profileImage'];

        context.read<ChatDatabase>().updateData();
        context.read<AuctionDatabase>().updateData();
      });
    });

    super.initState();
  }

  final List<Widget> homePages = [
    ProductsPage(
      // key based on epoc time
      key: Key('/home${DateTime.now().millisecondsSinceEpoch}'),
      navigatorKey: navItemHome,
    ),
    ChatsPage(
      key: const Key("/chats"),
      navigatorKey: navItemChats,
    ),
    AuctionsPage(
      key: const Key("/auctions"),
      navigatorKey: navItemAuctions,
    ),
    ShippingPage(
      key: const Key("/shipments"),
      navigatorKey: navItemShipments,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final chats = context.watch<ChatDatabase>();
    final auctions = context.watch<AuctionDatabase>();
    final shipments = context.watch<ShipmentDatabase>();
    final notification = context.watch<NotificationDatabase>();

    NavigationRailLabelType labelType = NavigationRailLabelType.all;

    final isSmallScreen = MediaQuery.of(context).size.width < 720;

    var drawer = Drawer(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 240,
            width: double.infinity,
            child: DrawerHeader(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_profileImage),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _name,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _email,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
              children: [
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(FluentIcons.home_24_filled),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0), child: Text('Home')),
                  onPressed: () {
                    _onItemTapped(0);
                    Navigator.pop(context);
                  },
                ),
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: Badge(
                    label: Text(chats.chatsMap.length.toString()),
                    child: const Icon(FluentIcons.chat_24_filled),
                  ),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('Chats')),
                  onPressed: () {
                    _onItemTapped(1);
                    Navigator.pop(context);
                  },
                ),
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: Badge(
                    label: Text(auctions.auctionsMap.length.toString()),
                    child: const Icon(FluentIcons.shopping_bag_24_filled),
                  ),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('Auctions')),
                  onPressed: () {
                    _onItemTapped(2);
                    Navigator.pop(context);
                  },
                ),
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: Badge(
                    label: Text(shipments.shipments.length.toString()),
                    child:
                        const Icon(FluentIcons.vehicle_truck_profile_24_filled),
                  ),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('Shipments')),
                  onPressed: () {
                    _onItemTapped(3);
                    Navigator.pop(context);
                  },
                ),
                // add border to the bottom of the drawer
                const Divider(),
                // notification
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: Badge(
                    label: Text(notification.notifications.length.toString()),
                    child: const Icon(FluentIcons.alert_24_filled),
                  ),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('Notifications')),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/notifications',
                      arguments: {
                        'from': context,
                      },
                    );
                  },
                ),
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(FluentIcons.heart_24_filled),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('Favorites')),
                  onPressed: () {},
                ),
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(FluentIcons.settings_24_filled),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('Settings')),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/settings',
                      arguments: {
                        'from': context,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
              // get the bottom padding of the screen
              padding: EdgeInsets.only(
                  left: 10.0,
                  right: 10.0,
                  bottom: MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              FirebaseAuth.instance.signOut().then((value) => {
                                    //clear the stack and navigate to the initial page
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const InitialPage(),
                                      ),
                                      (Route<dynamic> route) => false,
                                    ),

                                    //clear the stack and navigate to the home page
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Logged out successfully'),
                                      ),
                                    ),
                                  });
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250.0, 50.0),
                  ),
                  icon: const Icon(FluentIcons.sign_out_24_filled),
                  label: const Text('Sign Out'),
                ),
              )),
        ],
      ),
    );

    return RepaintBoundary(
      child: isSmallScreen
          ? Scaffold(
              drawer: drawer,
              key: scaffoldKey,
              body:
                  NewWidget(pageController: _pageController, pages: homePages),
              bottomNavigationBar: NavigationBar(
                surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                onDestinationSelected: (int index) {
                  _onItemTapped(index);
                },
                selectedIndex: _selectedIndex,
                destinations: [
                  NavigationDestination(
                    selectedIcon: Icon(FluentIcons.home_16_filled),
                    icon: Icon(FluentIcons.home_16_regular),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    selectedIcon: Badge(
                      label: Text(chats.chatsMap.length.toString()),
                      child: Icon(FluentIcons.chat_16_filled),
                    ),
                    icon: Badge(
                      label: Text(chats.chatsMap.length.toString()),
                      child: Icon(FluentIcons.chat_16_regular),
                    ),
                    label: 'Chats',
                  ),
                  NavigationDestination(
                    selectedIcon: Badge(
                      label: Text(auctions.auctionsMap.length.toString()),
                      child: Icon(FluentIcons.shopping_bag_16_filled),
                    ),
                    icon: Badge(
                      label: Text(auctions.auctionsMap.length.toString()),
                      child: Icon(FluentIcons.shopping_bag_16_regular),
                    ),
                    label: 'Auctions',
                  ),
                  NavigationDestination(
                    selectedIcon: Badge(
                      label: Text(shipments.shipments.length.toString()),
                      child: Icon(FluentIcons.vehicle_truck_profile_16_filled),
                    ),
                    icon: Badge(
                      label: Text(shipments.shipments.length.toString()),
                      child: Icon(FluentIcons.vehicle_truck_profile_16_regular),
                    ),
                    label: 'Shipments',
                  ),
                ],
              ),
            )
          : Scaffold(
              drawer: drawer,
              key: scaffoldKey,
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) {
                      _onItemTapped(index);
                    },
                    labelType: labelType,
                    destinations: _destinationLarge,
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: NewWidget(
                        pageController: _pageController, pages: homePages),
                  )
                ],
              ),
            ),
    );
  }
}

class NewWidget extends StatelessWidget {
  const NewWidget({
    super.key,
    required PageController pageController,
    required List<Widget> pages,
  })  : _pageController = pageController,
        homePages = pages;

  final PageController _pageController;
  final List<Widget> homePages;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: homePages,
    );
  }
}
