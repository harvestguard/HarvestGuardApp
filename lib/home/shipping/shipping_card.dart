import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/carousel.dart';
import 'package:harvest_guard/services/tools.dart';

class ShipmentCard extends StatefulWidget {
  final Map<String, dynamic> auctionInfo;
  final Map<String, dynamic> itemInfo;
  final VoidCallback? onTap;
  final double bid;
  final String bidUid;
  final String auctionId;
  final Widget? footerWidget;
  final String? messageId;
  final String? chatId;
  final double? height;

  const ShipmentCard({
    super.key,
    required this.auctionInfo,
    required this.auctionId,
    required this.bidUid,
    required this.bid,
    required this.itemInfo,
    this.onTap,
    this.footerWidget,
    this.messageId,
    this.chatId,
    this.height,
  });

  @override
  State<ShipmentCard> createState() => _ShipmentCardState();
}

class _ShipmentCardState extends State<ShipmentCard> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      child: InkWell(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: widget.height ??
                  constraints
                      .maxHeight, // Use provided height or expand to parent
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Images Carousel
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CarouselWidget(
                            images: widget.itemInfo['images'].cast<String>(),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10.0)),
                            indicatorPadding: 20.0,
                            indicatorPosition: Alignment.bottomRight,
                            indicatorVisible: true,
                            internetFiles: true,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Product Details
                        Expanded(
                          child: SizedBox(
                            // Added SizedBox to provide height constraint
                            height: 100, // Match the height of the carousel
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.itemInfo['item'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${widget.itemInfo['quantity']} pcs',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(), // Now correctly placed between content
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total payment',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.6),
                                          ),
                                    ),
                                    Text(
                                      '₱${widget.bid.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
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
                  // Shipping Details Section
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.1),
                      border: Border(
                        top: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shipping Address',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.6),
                                  ),
                        ),
                         Text(
                          widget.auctionInfo['buyerName'],
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,)
                        ),
                        Text(
                          widget.auctionInfo['buyerAddress'],
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color
                                        ?.withOpacity(0.8),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Contact Number',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.6),
                                  ),
                        ),
                        Text(
                          widget.auctionInfo['buyerContact'],
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Footer Actions
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: widget.footerWidget ??
                        const SizedBox(
                          width: double.infinity,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}
