import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/carousel.dart';
import 'package:harvest_guard/global.dart';
import 'package:harvest_guard/services/chat.dart';
import 'package:intl/intl.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.adminId, required this.productId});
  final String productId;
  final String adminId;

  

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with AutomaticKeepAliveClientMixin<ProductPage> {
  @override
  bool get wantKeepAlive => true;


  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      startingOpacity: 0.9,
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      minRadius: 20,
      onDismissed: () {
        Navigator.of(context).pop();
      },
      direction: DismissiblePageDismissDirection.multi,
      isFullScreen: false,
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(widget.adminId)
            .collection('items')
            .doc(widget.productId)
            .snapshots(),
        builder: (context, snapshot) {
          var date = DateTime.fromMillisecondsSinceEpoch(int.tryParse(widget.productId) ?? DateTime.now().millisecondsSinceEpoch);
          
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final product = snapshot.data!.data()!;

          var isFavorite = product['isFavorite'] ?? false;

          return Scaffold(
            body: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Column(
                  children: [
                    Hero(
                      tag: widget.productId,
                      child: SizedBox(
                        height: 300,
                        child: Stack(
                          children: [
                            CarouselWidget(
                              images: product['images'].cast<String>(),
                              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                              indicatorPadding: 20.0,
                              indicatorPosition: Alignment.bottomRight,
                              indicatorVisible: true,
                              internetFiles: true,
                            ),
                            Positioned(
                              top: 5,
                              left: 5,
                              child: IconButton(
                                icon: const Icon(
                                    FluentIcons.arrow_left_24_filled),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (product['item'] as String).toUpperCase(),
                            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          Text(
                            product['description'],
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 25.0),
                          const Opacity(
                              opacity: 0.7,
                              child: Text('Price',
                                  style: TextStyle(fontSize: 14.0))),
                          const SizedBox(height: 5.0),
                          Text(
                            '₱${(product['price'] * 1.00).toStringAsFixed(2)} per item',
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 25.0),
                          const Opacity(
                              opacity: 0.7,
                              child: Text('Quantity',
                                  style: TextStyle(fontSize: 14.0))),
                          const SizedBox(height: 5.0),
                          Text(
                            '${product['quantity']}',
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 25.0),
                          const Opacity(
                              opacity: 0.7,
                              child: Text('Date added',
                                  style: TextStyle(fontSize: 14.0))),
                          const SizedBox(height: 5.0),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(date),
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 15.0),

                          OverflowBar(
                            spacing: 10.0,
                            alignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                   Navigator.of(context).pushNamed(
                                    '/chat',
                                    arguments: {
                                      'chat': Chat(
                                        chat: chatDatabase.chatsMap,
                                        chatMembers: [widget.adminId, FirebaseAuth.instance.currentUser!.uid],
                                      ),
                                      'from': context.findAncestorWidgetOfExactType<
                                          ProductPage>()!,
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                                  minimumSize: const Size(250.0, 50.0),
                                ),
                                icon: const Icon(FluentIcons.chat_24_filled),
                                label: const Text('Chat with Seller'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(widget.adminId)
                                    .collection('items')
                                    .doc(widget.productId)
                                    .update({'isFavorite': isFavorite = !isFavorite})
                                    .then((value) =>
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isFavorite ? 'Added to favorites' : 'Removed from favorites'),
                                          action: SnackBarAction(
                                            label: 'Undo',
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                .collection('products')
                                                .doc(widget.adminId)
                                                .collection('items')
                                                .doc(widget.productId)
                                                .update({'isFavorite': isFavorite = !isFavorite})
                                                .then((value) =>
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Undo successful'),
                                                    ),
                                                  )
                                                );
                                            },
                                          ),
                                        ),
                                      )
                                    );
                                },
                                style: ElevatedButton.styleFrom(
                                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                                  minimumSize: const Size(250.0, 50.0),
                                ),
                                icon: Icon(isFavorite ? FluentIcons.star_24_filled : FluentIcons.star_24_regular),
                                label: Text(isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                              ),
                              // notify when auction starts
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Notify me
                                },
                                style: ElevatedButton.styleFrom(
                                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                                  minimumSize: const Size(250.0, 50.0),
                                ),
                                icon: const Icon(FluentIcons.alert_24_filled),
                                label: const Text('Notify me for auctions'),
                              ),
                            ],
                          ),
                          
                          
                          
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
