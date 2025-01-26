import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final BuildContext previousContext;
  @override
  final RouteSettings settings;

  SlidePageRoute({
    required this.builder,
    required this.previousContext,
    required this.settings,
  }) : super(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const oldScreenBegin = Offset.zero;
            const oldScreenEnd = Offset(-0.3, 0.0);
            const curve = Curves.easeInOutCubic;

            var slideAnimation = Tween(
              begin: begin,
              end: end,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            var oldScreenAnimation = Tween(
              begin: oldScreenBegin,
              end: oldScreenEnd,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            var scaleAnimation = Tween(
              begin: 1.0,
              end: 0.95,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));


            Future<ui.Image?> captureScreen() async {
              try {
                // Find the render object in the tree
                final RenderObject? renderObject = previousContext.findRenderObject();
                if (renderObject == null) return null;

                // Convert it to a RepaintBoundary if possible
                if (renderObject is! RenderRepaintBoundary) {
                  debugPrint('Warning: Found render object is not a RenderRepaintBoundary');
                  return null;
                }

                // Capture the image
                final ui.Image image = await renderObject.toImage(
                  pixelRatio: WidgetsBinding.instance.window.devicePixelRatio,
                );
                return image;
              } catch (e) {
                debugPrint('Failed to capture screenshot: $e');
                return null;
              }
            }

            Widget buildPreviousScreen(
              Animation<Offset> position,
              Animation<double> scale,
            ) {
              return FutureBuilder<ui.Image?>(
                future: captureScreen(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  return SlideTransition(
                    position: position,
                    child: Transform.scale(
                      scale: scale.value,
                      child: RawImage(
                        image: snapshot.data,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              );
            }

            return Stack(
              children: [
                // Screenshot of old screen with scale animation
                buildPreviousScreen(
                  oldScreenAnimation,
                  scaleAnimation,
                ),
                // New screen with shadow and slide animation
                SlideTransition(
                  position: slideAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 25.0,
                          spreadRadius: 2.0,
                          offset: const Offset(-2, 0),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ],
            );
          },
        ) {
    // Initialize screenshot in constructor body
  }

  

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => true;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => true;
}