import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harvest_guard/theme.dart';

import 'custom/carousel.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {  
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    // show loading dialog that will be dismissed after registration is successful
    

    return Theme(
      // change the color of notification bar
      data: Theme.of(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent
          ),
          child: Column(
            children: <Widget>[
              Theme(
                data: ThemeData(colorScheme: MaterialTheme.darkScheme().toColorScheme()), 
                child: 
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const CarouselWidget(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                            indicatorPadding: 30.0,
                            images: [
                              'assets/front_page_images/farmer_3.jpg',
                              'assets/front_page_images/farmer_4.jpg',
                              'assets/front_page_images/farmer_5.jpg',
                            ]),
                        Positioned(
                          top: MediaQuery.of(context).padding.bottom + 30,
                          child: Image.asset(
                            'assets/banner.png',
                            fit: BoxFit.cover,
                            height: 70,
                            color: ThemeData(colorScheme: MaterialTheme.lightScheme().toColorScheme())
                                .colorScheme
                                .tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // add a title
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: <Widget>[
                    Text('WELCOME BACK!',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                    // add a subtitle
                    Text(
                      'Please select an option below to continue.',
                      style: textTheme.labelLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(220)),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: FilledButton(
                        onPressed: () => Navigator.pushNamed(context, '/login', arguments: {'from': widget}),
                        child: const Text('LOG-IN'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.pushNamed(context, '/guest-home', arguments: {'from': widget}),
                        child: const Text('LOG-IN as a GUEST'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                          elevation: 5
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/register', arguments: {'from': widget}),
                        child: const Text('REGISTER'),
                      ),
                    ),
                    // Navigation bar padding
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
