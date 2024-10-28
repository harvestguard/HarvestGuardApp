import 'package:flutter/material.dart';

enum FavoriteFilter { all, favorites, notFavorites }


class SettingsProvider with ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  bool isDynamicTheming = false;
  
  RangeValues priceFilter = const RangeValues(0, 1000);
  RangeValues quantityFilter = const RangeValues(0, 10000);
  FavoriteFilter favoriteFilters = FavoriteFilter.all;


  void setThemeMode(ThemeMode themeMode) {
    this.themeMode = themeMode;
    print(themeMode);
    notifyListeners();
  }

  void setDynamicTheming(bool isDynamicTheming) {
    this.isDynamicTheming = isDynamicTheming;
    print(isDynamicTheming);
    notifyListeners();
  }

  void setPriceFilter(RangeValues priceFilter) {
    this.priceFilter = priceFilter;
    print(priceFilter);
    notifyListeners();
  }

  void setQuantityFilter(RangeValues quantityFilter) {
    this.quantityFilter = quantityFilter;
    print(quantityFilter);
    notifyListeners();
  }

  void setFavoriteFilter(FavoriteFilter favoriteFilter) {
    favoriteFilters = favoriteFilter;
    print(favoriteFilter);
    notifyListeners();
  }
}

