import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/home/app_bar.dart';
import 'package:harvest_guard/home/auctions/auction_card.dart';
import 'package:harvest_guard/settings/settings_page.dart';
import 'package:provider/provider.dart';
import '../../global.dart';

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({required this.navigatorKey, required super.key});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage>
    with AutomaticKeepAliveClientMixin<AuctionsPage> {
  @override
  bool get wantKeepAlive => true;

  void _navigateToSettings() {
    Navigator.of(navigatorKeyMain.currentContext!).push(
      CupertinoPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  void _openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void _navigateToAuction(BuildContext context, String auctionUid) {
    Navigator.of(context).pushNamed(
      '/auction',
      arguments: {
        'auctionUid': auctionUid,
        'from': context.findAncestorWidgetOfExactType<AuctionsPage>(),
      },
    );
  }

  Widget _buildAuctionGrid(BuildContext context, AuctionDatabase auctionDatabase) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth ~/ 390;
    
    final List<MapEntry<String, dynamic>> auctions = 
        auctionDatabase.auctionsMap.entries.toList();

    return SliverToBoxAdapter(
      child: GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        itemCount: auctions.length,
        itemBuilder: (context, index) => _buildAuctionCard(context, auctions[index]),
      ),
    );
  }

  Widget _buildAuctionCard(BuildContext context, MapEntry<String, dynamic> auction) {
    final isLoading = auction.value['itemInfo'] == null;
    final bidders = _getSortedBidders(auction.value['bidUid']);
    final currentBid = _getCurrentBid(isLoading, bidders);

    return AuctionCard(
      isLoading: isLoading,
      product: auction.value['itemInfo'],
      bid: currentBid,
      bidCount: auction.value['bidUid'].length,
      epochStart: int.parse(auction.value['epochStart']),
      epochEnd: int.parse(auction.value['epochEnd']),
      onTap: () => _navigateToAuction(context, auction.key),
    );
  }

  List<dynamic> _getSortedBidders(dynamic bidUidData) {
    final bidders = bidUidData.entries.toList() as List;
    bidders.sort((a, b) => (b.value['bid']).compareTo(a.value['bid']));
    return bidders;
  }

  double _getCurrentBid(bool isLoading, List<dynamic> bidders) {
    if (isLoading || bidders.isEmpty) return 0.00;
    return bidders[0].value['bid'] * 1.00;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final auctionDatabase = context.watch<AuctionDatabase>();

    return Scaffold(
      body: CustomScrollView(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        slivers: [
          HomeAppBar(
            title: 'Auctions',
            leftIcon: IconButton(
              icon: const Icon(FluentIcons.list_24_filled),
              onPressed: _openDrawer,
            ),
            rightIcon: IconButton(
              icon: const Icon(FluentIcons.cart_24_regular),
              onPressed: () {
                // Cart functionality
              },
            ),
          ),
          _buildAuctionGrid(context, auctionDatabase),
        ],
      ),
    );
  }
}