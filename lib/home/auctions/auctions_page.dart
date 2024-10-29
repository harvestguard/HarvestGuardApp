import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:harvest_guard/custom/carousel.dart';
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
  String? status;

  late Stream<Map<String, dynamic>> _auctions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _auctions = Stream.value(Provider.of<AuctionDatabase>(context).auctionsMap);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final actions = [
      IconButton(
          icon: const Icon(FluentIcons.alert_16_filled), onPressed: () {}),
      IconButton(
          icon: const Icon(FluentIcons.person_circle_20_filled),
          onPressed: () => Navigator.of(navigatorKeyMain.currentContext!).push(
                CupertinoPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              )),
    ];

    return Scaffold(
      body: CustomScrollView(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        slivers: [
          HomeAppBar(
            title: 'Auctions',
            leftIcon: IconButton(
              icon: const Icon(FluentIcons.list_24_filled),
              onPressed: () {
                scaffoldKey.currentState!.openDrawer();
              },
            ),
            rightIcon: IconButton(
              icon: const Icon(FluentIcons.cart_24_regular),
              onPressed: () {
                // cart
              },
            ),
          ),
          StreamBuilder(
              stream: _auctions,
              builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (snapshot.hasError) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('An error occurred'),
                    ),
                  );
                } else if (snapshot.data == null) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('No auctions available'),
                    ),
                  );
                } else if (snapshot.hasData) {
                  final List<MapEntry<String, dynamic>> docs =
                      snapshot.data!.entries.toList();

                  return SliverToBoxAdapter(
                      child: GridView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, bottom: 10),
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                MediaQuery.of(context).size.width ~/ 390,
                            mainAxisSpacing: 5,
                            crossAxisSpacing: 5,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (BuildContext context, int index) {
                            final isLoading =
                                docs[index].value['itemInfo'] == null;
                            var bidders = docs[index]
                                .value['bidUid']
                                .entries
                                .toList() as List;
                            bidders.sort((a, b) =>
                                (b.value['bid']).compareTo(a.value['bid']));

                            return AuctionCard(
                                isLoading: isLoading,
                                product: docs[index].value['itemInfo'],
                                bid: isLoading
                                    ? 0.00
                                    : bidders.isEmpty
                                        ? 0.00
                                        : bidders[0].value['bid'] * 1.00,
                                bidCount: docs[index].value['bidUid'].length,
                                epochStart:
                                    int.parse(docs[index].value['epochStart']),
                                epochEnd:
                                    int.parse(docs[index].value['epochEnd']),
                                onTap: () {
                                  print(
                                      'nullme: ${context.findAncestorWidgetOfExactType<AuctionsPage>()}');
                                  Navigator.of(context).pushNamed(
                                    '/auction',
                                    arguments: {
                                      'auctionUid': docs[index].key,
                                      'from':
                                          context.findAncestorWidgetOfExactType<
                                              AuctionsPage>(),
                                    },
                                  );
                                });
                          }));
                }

                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No auctions available'),
                  ),
                );
              }),
        ],
      ),
    );
  }
}
