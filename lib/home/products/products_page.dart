import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';

// ignore: depend_on_referenced_packages
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:harvest_guard/custom/carousel.dart';
import 'package:harvest_guard/global.dart';
import 'package:harvest_guard/home/app_bar.dart';
import 'package:harvest_guard/home/products/product_page.dart';
import 'package:harvest_guard/settings/settings_provider.dart';
import 'package:provider/provider.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({required this.navigatorKey, required super.key});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with AutomaticKeepAliveClientMixin<ProductsPage> {
  @override
  bool get wantKeepAlive => true;

  Future<List<Map<String, dynamic>>>? _products;

  final ScrollController _scrollController = ScrollController();
  final _isAppBarCollapsed = ValueNotifier<bool>(false);
  List<SearchProductInfo> searchProductInfos = <SearchProductInfo>[];
  final Map<String, void Function()> _listeners = {};
  final List<Map<String, dynamic>> _allItems = [];

  void _startListeningData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot adminSnapshots =
          await firestore.collection('products').get();

      for (QueryDocumentSnapshot adminDoc in adminSnapshots.docs) {
        String adminUid = adminDoc.id;

        QuerySnapshot itemsSnapshot = await firestore
            .collection('products')
            .doc(adminUid)
            .collection('items')
            .get();

        void Function() cancel = firestore
            .collection('products')
            .doc(adminUid)
            .collection('items')
            .snapshots()
            .listen((QuerySnapshot itemsSnapshot) {
          // Remove all items related to this adminUid from _allItems
          _updateItemsList(adminUid, itemsSnapshot.docs);
        }).cancel;

        _listeners[adminUid] = cancel;
      }
    } catch (e) {
      print("Error fetching items: $e");
    }
  }

  void _updateItemsList(String adminUid, List<QueryDocumentSnapshot> itemDocs) {
    setState(() {
      // Remove all items related to this adminUid from _allItems
      _allItems.removeWhere((item) => item['adminUid'] == adminUid);

      // Add updated items
      for (QueryDocumentSnapshot itemDoc in itemDocs) {
        Map<String, dynamic> item = itemDoc.data()! as Map<String, dynamic>;
        item['adminUid'] = adminUid;
        item['itemUid'] = itemDoc.id;

        _allItems.add(item);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startListeningData();

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    bool isCollapsed = _scrollController.hasClients &&
        _scrollController.offset > (300 - 10 - kToolbarHeight);
    if (isCollapsed != _isAppBarCollapsed) {
      _isAppBarCollapsed.value =
          isCollapsed; // This will trigger rebuiding the text widget.
    }
  }

  @override
  void dispose() {
    _listeners.forEach((_, value) => value());

    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return RepaintBoundary(
        child: Scaffold(
            body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      slivers: [
        SliverAppBar.large(
          automaticallyImplyLeading: false,
          expandedHeight: 300,
          pinned: true,
          title: null,
          centerTitle: true,
          flexibleSpace: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Builder(builder: (BuildContext context) {
                final List<String> images = [];

                for (final item in _allItems) {
                  images.add((item['images'] as List)[0]);
                }

                return FlexibleSpaceBar(
                  background: CarouselWidget(
                    indicatorVisible: false,
                    borderRadius: const BorderRadius.all(Radius.circular(0)),
                    images: images,
                    internetFiles: true,
                  ),
                );
              }),
              ValueListenableBuilder(
                  valueListenable: _isAppBarCollapsed,
                  builder: (BuildContext context, bool value, Widget? child) {
                    return AnimatedOpacity(
                      opacity: value ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withAlpha(0),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(FluentIcons.list_24_regular),
                      onPressed: () {
                        scaffoldKey.currentState!.openDrawer();
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 200,
                      child: FlexibleSpaceBar(
                        background: null,
                        expandedTitleScale: 1.75,
                        titlePadding: const EdgeInsets.only(bottom: 10),
                        title: Text('Products',
                            style: Theme.of(context).textTheme.titleLarge),
                        centerTitle: true,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(FluentIcons.filter_24_regular),
                      onPressed: () async {
                        // create filter dialog
                        // get the upper context
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 30),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text('Filter',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall),
                                        const SizedBox(height: 20),
                                        const Text('Price range'),
                                        // Price range slider
                                        RangeSlider(
                                          values: settingsProvider.priceFilter,
                                          onChanged: (RangeValues values) {
                                            setState(() {
                                              settingsProvider
                                                  .setPriceFilter(values);
                                            });
                                          },
                                          min: 0,
                                          max: 1000,
                                          divisions: 10,
                                          labels: RangeLabels(
                                            '₱${settingsProvider.priceFilter.start.toInt()}',
                                            '₱${settingsProvider.priceFilter.end.toInt()}',
                                          ),
                                        ),
                                        const Text('Quantity'),
                                        RangeSlider(
                                          values:
                                              settingsProvider.quantityFilter,
                                          onChanged: (RangeValues values) {
                                            setState(() {
                                              settingsProvider
                                                  .setQuantityFilter(values);
                                            });
                                          },
                                          min: 0,
                                          max: 10000,
                                          divisions: 10,
                                          labels: RangeLabels(
                                            '${settingsProvider.quantityFilter.start.toInt()}',
                                            '${settingsProvider.quantityFilter.end.toInt()}',
                                          ),
                                        ),
                                        // favorite filter
                                        const SizedBox(height: 10),
                                        // segmented button
                                        const Text('Favorites'),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            FilterChip(
                                              label: const Text('All'),
                                              selected: settingsProvider
                                                      .favoriteFilters ==
                                                  FavoriteFilter.all,
                                              onSelected: (selected) {
                                                setState(() => settingsProvider
                                                    .setFavoriteFilter(
                                                        FavoriteFilter.all));
                                              },
                                            ),
                                            FilterChip(
                                              label: const Text('Favorites'),
                                              selected: settingsProvider
                                                      .favoriteFilters ==
                                                  FavoriteFilter.favorites,
                                              onSelected: (selected) {
                                                setState(() => settingsProvider
                                                    .setFavoriteFilter(
                                                        FavoriteFilter
                                                            .favorites));
                                              },
                                            ),
                                            FilterChip(
                                              label:
                                                  const Text('Not Favorites'),
                                              selected: settingsProvider
                                                      .favoriteFilters ==
                                                  FavoriteFilter.notFavorites,
                                              onSelected: (selected) {
                                                setState(() => settingsProvider
                                                    .setFavoriteFilter(
                                                        FavoriteFilter
                                                            .notFavorites));
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    )));
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: SearchProductsHeaderDelegate(
            searchProductInfo: searchProductInfos,
            databaseName: 'productsSearchHistory',
            barHintText: 'Search products',
            cont: context,
            onTap: () async {
              searchProductInfos.clear();

              for (final item in _allItems) {
                searchProductInfos.add(SearchProductInfo(
                  name: item['item'] as String,
                  sellerUid: item['adminUid'],
                  itemUid: item['itemUid'],
                  thumbProductImage: (item['images'] as List<dynamic>)[0],
                ));
              }
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Builder(builder: (BuildContext context) {
            return _allItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width ~/ 200,
                      mainAxisSpacing: 5,
                      mainAxisExtent: 260,
                      crossAxisSpacing: 5,
                    ),
                    itemCount: _allItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      var item = _allItems[index];

                      final images = item['images'] as List<dynamic>;

                      return Stack(
                        children: [
                          Card(
                            surfaceTintColor:
                                Theme.of(context).colorScheme.surfaceTint,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                    tag: item['itemUid'],
                                    child: SizedBox(
                                        height: 190,
                                        child: CarouselWidget(
                                          indicatorVisible: false,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(10)),
                                          images: images.cast<String>(),
                                          internetFiles: true,
                                        ))),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15, right: 15, top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (item['item'] as String).toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      ),
                                      Text(
                                        '₱${(item['price'] * 1.00).toStringAsFixed(2)} per item',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                                overflow: TextOverflow.ellipsis,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                    context.pushTransparentRoute(ProductPage(
                                        sellerUid: item['adminUid'] as String,
                                        productId: item['itemUid'] as String));
                                  },
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
          }),
        )
      ],
    )));
  }
}
