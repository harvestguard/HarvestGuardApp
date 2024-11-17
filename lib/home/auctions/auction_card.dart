import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/carousel.dart';
import 'package:harvest_guard/services/countdown.dart';
import 'package:intl/intl.dart';
// Assuming CarouselWidget is in this path

class AuctionCard extends StatelessWidget {
  final Map<String, dynamic>? product;
  final double bid;
  final int bidCount;
  final int epochStart;
  final int epochEnd;
  final double? height;
  final VoidCallback? onTap;
  final String? bidLabel;
  final EdgeInsetsGeometry padding;
  final bool isLoading;

  const AuctionCard({
    super.key,
    required this.product,
    required this.bid,
    required this.bidCount,
    required this.epochStart,
    required this.epochEnd,
    this.height,
    this.bidLabel = 'Highest Bid',
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.isLoading = false,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 2,
      locale: 'en_PH',
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || product == null) {
      return _buildSkeletonCard(context);
    }

    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: height ??
                  constraints
                      .maxHeight, // Use provided height or expand to parent
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carousel Section
                  SizedBox(
                    height: 170,
                    child: CarouselWidget(
                      images: product!['images'].cast<String>(),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10.0)),
                      indicatorPadding: 20.0,
                      indicatorPosition: Alignment.bottomRight,
                      indicatorVisible: true,
                      internetFiles: true,
                    ),
                  ),

                  // Content Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Quantity
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product!['item'].toString().toUpperCase(),
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      '${product!['quantity']} pcs',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),

                              // Price Information
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Starting Price',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(
                                            (product!['quantity'] *
                                                    product!['price'])
                                                .toDouble(),
                                          ),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          '(${_formatCurrency(product!['price'].toDouble())} per item)',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bidLabel!,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(bid),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(), // This will push the footer to the bottom
                        // Footer Section
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Bid Count
                              Row(
                                children: [
                                  Icon(
                                    Icons.gavel,
                                    size: 16.0,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '$bidCount bids',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              // Time Remaining
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 16.0,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Countdown(
                                      epochStart: epochStart,
                                      epochEnd: epochEnd)
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSkeletonCard(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: height ??
                constraints
                    .maxHeight, // Use provided height or expand to parent
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16.0),
                    ),
                  ),
                ),
                Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Container(
                                  width: 100,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Container(
                                  width: 100,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ],
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
