import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => controller.clear(),
      );
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  final String _otpcode = '';
  final String _verificationId = '';

  Future _login(BuildContext context) async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Make the dialog not cancellable
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Disable back button
          child: const AlertDialog(
            title: Center(
              child: Text('Loading'),
            ),
            content: Center(
              heightFactor: 2,
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        );
      },
    );

    await FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: _usernameController.text,
      password: _passwordController.text,
    )
        .then((value) async {
      var isAdmin = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(value.user!.uid)
          .child('isAdmin')
          .once();

      if (isAdmin.snapshot.value != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin should login from the web app'),
          ),
        );
        FirebaseAuth.instance.signOut();
      } else {
        Navigator.of(context).pop();
        // clear the stack and navigate to the home page
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          arguments: {'from': widget},
          (Route<dynamic> route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful'),
          ),
        );
      }
    }).catchError((error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.message}'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar.large(
            title: Text('Login'),
            actions: [],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // add text fields for username and password
                Padding(
                  padding: const EdgeInsets.only(
                      left: 18, right: 18, bottom: 0, top: 16),
                  child: Text(
                    'Welcome to HarvestGuard',
                    style: textTheme.headlineSmall,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 18, right: 18, bottom: 32),
                  child: Text(
                    'Login to your account',
                    style: textTheme.titleSmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18),
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(FluentIcons.person_24_filled),
                      suffixIcon: _ClearButton(controller: _usernameController),
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      helperText: 'Email must be a valid email address.',
                      fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 18, right: 18, bottom: 30),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(FluentIcons.lock_closed_24_filled),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? FluentIcons.eye_24_filled
                              : FluentIcons.eye_off_24_filled,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      helperText: 'Password must be at least 8 characters long',
                      fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    style: TextButton.styleFrom(
                      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                    ),
                    onPressed: () => _login(context),
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
