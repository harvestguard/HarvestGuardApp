import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:harvest_guard/custom/carousel.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/home/app_bar.dart';
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
                                MediaQuery.of(context).size.width ~/ 350,
                            mainAxisSpacing: 5,
                            mainAxisExtent: 170,
                            crossAxisSpacing: 5,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (BuildContext context, int index) {
                            var doc = docs[index].value;
                            var item = doc['itemInfo'];
                            print('0, list: $docs ');

                            if (item == null) {
                              return const SizedBox();
                            }

                            if (doc['status'] == 0) {
                              status = 'Starts in ${doc['statusTime']}';
                            } else if (doc['status'] == 1) {
                              status = 'Ends in ${doc['statusTime']}';
                            } else if (doc['status'] == -1) {
                              status = 'Ended';
                            }

                            return Stack(
                              children: [
                                Card(
                                  surfaceTintColor:
                                      Theme.of(context).colorScheme.surfaceTint,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      // crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                            height: 150,
                                            width: 150,
                                            child: CarouselWidget(
                                              indicatorVisible: false,
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10)),
                                              images:
                                                  item['images'].cast<String>(),
                                              internetFiles: true,
                                            )),
                                        const SizedBox(width: 15),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5),
                                          child: Column(
                                            // mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                  (item['item'] as String)
                                                      .toUpperCase(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        height: 1,
                                                      )),
                                              Text(
                                                'by ${doc['adminInfo']['firstName']} ${doc['adminInfo']['middleName']} ${doc['adminInfo']['lastName']}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.7)),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '₱${item['price'].toStringAsFixed(2)} per item',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary),
                                              ),

                                              const SizedBox(height: 5),

                                              // flex the height of the column
                                              const Spacer(),

                                              Row(children: [
                                                Text(
                                                  'Highest bid: ',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.85)),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '₱${doc['highestBid'].toStringAsFixed(2)}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.85)),
                                                ),
                                              ]),

                                              Row(children: [
                                                Text(
                                                  'Number of bids: ',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.85)),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  doc['bidUid']
                                                      .length
                                                      .toString(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.85)),
                                                ),
                                              ]),

                                              const Spacer(),

                                              Row(children: [
                                                const Opacity(
                                                  opacity: 0.7,
                                                  child: Icon(
                                                    FluentIcons
                                                        .timer_12_regular,
                                                    size: 14,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  status ?? 'Loading...',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.7)),
                                                ),
                                              ]),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        splashColor: Theme.of(context)
                                            .highlightColor
                                            .withOpacity(0.5),
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                            '/auction',
                                            arguments: {
                                              'auctionUid': docs[index].key,
                                              'from': context.findAncestorWidgetOfExactType<AuctionsPage>()!,
                                            },
                                          );
                                        },
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
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
