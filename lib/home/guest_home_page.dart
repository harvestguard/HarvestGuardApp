import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:harvest_guard/global.dart';
import 'package:harvest_guard/home/auctions/auctions_page.dart';
import 'package:harvest_guard/home/products/products_page.dart';

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  GuestHomePageState createState() => GuestHomePageState();
}

int _selectedIndex = 0;

class GuestHomePageState extends State<GuestHomePage>
    with AutomaticKeepAliveClientMixin<GuestHomePage> {
  @override
  bool get wantKeepAlive => true;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      selectedIcon: Icon(FluentIcons.home_16_filled),
      icon: Icon(FluentIcons.home_16_regular),
      label: 'Home',
    ),
    const NavigationDestination(
      selectedIcon: Icon(FluentIcons.shopping_bag_16_filled),
      icon: Icon(FluentIcons.shopping_bag_16_regular),
      label: 'Auctions',
    ),
  ];

  final List<NavigationRailDestination> _destinationLarge = const [
    NavigationRailDestination(
      selectedIcon: Icon(FluentIcons.home_16_filled),
      icon: Icon(FluentIcons.home_16_regular),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      selectedIcon: Icon(FluentIcons.shopping_bag_16_filled),
      icon: Icon(FluentIcons.shopping_bag_16_regular),
      label: Text('Auctions'),
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
        return navItemAuctions;
      default:
        return navItemHome;
    }
  }

  final List<Widget> homePages = [
    ProductsPage(
      key: Key('/home${DateTime.now().millisecondsSinceEpoch}'),
      navigatorKey: navItemHome,
    ),
    AuctionsPage(
      key: const Key("/auctions"),
      navigatorKey: navItemAuctions,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);

    NavigationRailLabelType labelType = NavigationRailLabelType.all;
    final isSmallScreen = MediaQuery.of(context).size.width < 720;

    var drawer = Drawer(
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 240,
            width: double.infinity,
            child: DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_circle, size: 100),
                  SizedBox(height: 10),
                  Text(
                    'Guest User',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
              children: [
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
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
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(FluentIcons.shopping_bag_24_filled),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('Auctions')),
                  onPressed: () {
                    _onItemTapped(1);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                FilledButton.tonalIcon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 25.0)),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(FluentIcons.person_24_filled),
                  label: const Padding(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('Sign In')),
                  onPressed: () {
                    Navigator.pushNamed(context, '/login', arguments: {'from': widget});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return RepaintBoundary(
      child: isSmallScreen
          ? Scaffold(
              drawer: drawer,
              key: scaffoldKey,
              body: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: homePages,
              ),
              bottomNavigationBar: NavigationBar(
                surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                onDestinationSelected: (int index) {
                  _onItemTapped(index);
                },
                selectedIndex: _selectedIndex,
                destinations: _destinations,
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
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: homePages,
                    ),
                  )
                ],
              ),
            ),
    );
  }
}