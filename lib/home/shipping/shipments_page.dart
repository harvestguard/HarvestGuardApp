import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/global.dart';
import 'package:harvest_guard/home/app_bar.dart';
import 'package:harvest_guard/home/shipping/shipping_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ShippingPage extends StatelessWidget {
  const ShippingPage({required this.navigatorKey, super.key});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final shipmentDatabase = context.watch<ShipmentDatabase>();

    return 
    RepaintBoundary(
      child: 
    Scaffold(
      body: CustomScrollView(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar
          HomeAppBar(
            title: 'Shipments',
            leftIcon: IconButton(
              icon: const Icon(FluentIcons.list_24_filled),
              onPressed: _openDrawer,
            ),
            rightIcon: IconButton(
              icon: const Icon(FluentIcons.vehicle_truck_profile_24_regular),
              onPressed: () {
                // Cart functionality
              },
            ),
          ),

          // Shipping List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: shipmentDatabase.isLoading
                ? _buildLoadingList()
                : _buildShippingList(context, shipmentDatabase),
          ),
        ],
      )
      ),
    );
  }

  void _openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildLoadingList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => const ShippingItemSkeleton(),
        childCount: 5,
      ),
    );
  }

  Widget _buildShippingList(BuildContext context, ShipmentDatabase database) {
    if (database.shipments.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FluentIcons.box_24_regular,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No shipping items found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = database.shipments.entries.elementAt(index);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShipmentCard(
              auctionId: entry.key,
              bid: entry.value['shippingInfo']['totalBid'] * 1.0,
              height: 380,
              showContact: false,
              itemInfo:
                  Map<String, dynamic>.from(entry.value['productInfo'] as Map),
              auctionInfo:
                  Map<String, dynamic>.from(entry.value['auctionInfo'] as Map),
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/delivery-tracking',
                  arguments: {
                    'shipmentId': entry.key,
                    'shippingData': entry.value,
                    'from': context,
                  },
                );
              },
              footerWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shipping Status',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final statusMap = Map<String, dynamic>.from(
                          entry.value['shippingInfo']['status'] ?? {});
                      final latestEntry = statusMap.entries
                          .reduce((a, b) => a.key.compareTo(b.key) > 0 ? a : b);
                      final date = DateTime.fromMillisecondsSinceEpoch(
                          int.parse(latestEntry.key));
                      return Text(
                        date.toString().substring(0, 16),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final statusMap = Map<String, dynamic>.from(
                          entry.value['shippingInfo']['status'] ?? {});
                      final latestEntry = statusMap.entries
                          .reduce((a, b) => a.key.compareTo(b.key) > 0 ? a : b);
                      return Text(
                        latestEntry.value.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        childCount: database.shipments.length,
      ),
    );
  }
}

class ShippingItemSkeleton extends StatelessWidget {
  final double? height;

  const ShippingItemSkeleton({
    super.key,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: height ?? constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image carousel skeleton
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Product details skeleton
                      Expanded(
                        child: SizedBox(
                          height: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Title skeleton
                                  Container(
                                    width: 120,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  // Quantity badge skeleton
                                  Container(
                                    width: 60,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Price skeleton
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 100,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Shipping details section skeleton
                Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Footer skeleton
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
