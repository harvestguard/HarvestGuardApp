import 'package:flutter/material.dart';
import 'dart:async';

import '../global.dart';

class CarouselWidget extends StatefulWidget {
  final List<String> images;
  final BorderRadius borderRadius;
  final double indicatorPadding;
  final AlignmentGeometry indicatorPosition;
  final bool indicatorVisible;
  final bool internetFiles;

  const CarouselWidget({
    super.key,
    required this.images,
    this.borderRadius = const BorderRadius.all(Radius.circular(20.0)),
    this.indicatorPadding = 20.0,
    this.indicatorPosition = Alignment.bottomRight,
    this.indicatorVisible = true,
    this.internetFiles = false,
  });

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  int _currentIndex = 0;
  late PageController _pageController;
  late Timer _timer;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentIndex < widget.images.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.indicatorPadding;
    final images = widget.images;
    final borderRadius = widget.borderRadius;
    final indicatorPosition = widget.indicatorPosition;

    double? leftPadding;
    double? rightPadding;
    double? topPadding;
    double? bottomPadding;

    if (indicatorPosition == Alignment.bottomCenter) {
      bottomPadding = padding;
    } else if (indicatorPosition == Alignment.topCenter) {
      topPadding = padding;
    } else if (indicatorPosition == Alignment.centerLeft) {
      leftPadding = padding;
    } else if (indicatorPosition == Alignment.centerRight) {
      rightPadding = padding;
    } else if (indicatorPosition == Alignment.topLeft) {
      topPadding = padding;
      leftPadding = padding;
    } else if (indicatorPosition == Alignment.topRight) {
      topPadding = padding;
      rightPadding = padding;
    } else if (indicatorPosition == Alignment.bottomLeft) {
      bottomPadding = padding;
      leftPadding = padding;
    } else if (indicatorPosition == Alignment.bottomRight) {
      bottomPadding = padding;
      rightPadding = padding;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        alignment: indicatorPosition,
        children: [
          Positioned(
            child: 
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withAlpha(100),
              ),
            ),
          ), 
          PageView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: images.length,
            controller: _pageController,
            onPageChanged: (value) {
              setState(() {
                _currentIndex = value;
              });
            },
            itemBuilder: (context, index) {
              if (widget.internetFiles) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                );
              } else {
                return Image.asset(
                  images[index],
                  fit: BoxFit.cover,
                );
              }
            },
          ),
          if (widget.indicatorVisible)
            Positioned(
                left: leftPadding,
                right: rightPadding,
                top: topPadding,
                bottom: bottomPadding,
                child: Padding(
                  padding: EdgeInsets.only(left: padding / 4),
                  child: Row(
                    children: List.generate(
                        images.length,
                        (index) =>
                            IndicatorDot(isActive: index == _currentIndex)),
                  ),
                )),
        ],
      ),
    );
  }
}

class IndicatorDot extends StatelessWidget {
  final bool isActive;
  final EdgeInsets indicatorPadding;
  final double indicatorWidth;
  final double indicatorHeight;
  final BorderRadius? indicatorBorderRadius;
  const IndicatorDot({
    super.key,
    required this.isActive,
    this.indicatorPadding = const EdgeInsets.all(1.5),
    this.indicatorWidth = 12.0,
    this.indicatorHeight = 6.0,
    this.indicatorBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorBrdr = (indicatorBorderRadius) ??
        BorderRadius.all(
          Radius.circular(
              MediaQuery.of(context).getProportionateScreenWidth(12)),
        );

    return Container(
      margin: indicatorPadding,
      height:
          MediaQuery.of(context).getProportionateScreenHeight(indicatorHeight),
      width: MediaQuery.of(context).getProportionateScreenWidth(indicatorWidth),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        borderRadius: indicatorBrdr,
      ),
    );
  }
}
