import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/front_page.dart';
import 'package:harvest_guard/global.dart';
import 'package:harvest_guard/settings/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin<SettingsPage> {
  @override
  bool get wantKeepAlive => true;
  final TextEditingController colorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final List<DropdownMenuEntry<ThemeMode>> themeModeEntries = [
      const DropdownMenuEntry(
        value: ThemeMode.system,
        label: 'System',
      ),
      const DropdownMenuEntry(
        value: ThemeMode.light,
        label: 'Light',
      ),
      const DropdownMenuEntry(
        value: ThemeMode.dark,
        label: 'Dark',
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar.large(
            title: Text('Settings'),
            actions: [],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: <Widget>[
                ListTile(
                  title: const Text("Theme Mode:"),
                  trailing: DropdownMenu<ThemeMode>(
                    controller: colorController,
                    initialSelection: settingsProvider.themeMode,
                    enableFilter: false,
                    dropdownMenuEntries: themeModeEntries,
                    inputDecorationTheme:
                        const InputDecorationTheme(filled: true),
                    onSelected: (ThemeMode? mode) {
                      setState(() {
                        final provider = Provider.of<SettingsProvider>(context,
                            listen: false);
                        provider.setThemeMode(mode!);
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Dynamic Color'),
                  trailing: Switch(
                    value: settingsProvider.isDynamicTheming,
                    onChanged: (bool value) {
                      setState(() {
                        final provider = Provider.of<SettingsProvider>(context,
                            listen: false);
                        provider.setDynamicTheming(value);
                      });
                    },
                  ),
                ),
                // logout button
                ListTile(
                  title: const Text('Logout'),
                  onTap: () {
                    setState(() {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text(
                                    'Are you sure you want to logout?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      FirebaseAuth.instance
                                          .signOut()
                                          .then((value) => {
                                                //clear the stack and navigate to the initial page
                                                Navigator.of(context)
                                                    .pushAndRemoveUntil(
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const InitialPage()),
                                                        (Route<dynamic>
                                                                route) =>
                                                            false),

                                                chatDatabase.forceDispose(),
                                                notificationDatabase
                                                    .forceDispose(),
                                                auctionDatabase.forceDispose(),
                                                shipmentDatabase.forceDispose(),
                                                //clear the stack and navigate to the home page
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Logged out successfully'),
                                                  ),
                                                )
                                              });
                                    },
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ));
                    });
                  },
                ),
                ElevatedButton(
                  child: const Text('Reset'),
                  onPressed: () => setState(() {
                    final provider =
                        Provider.of<SettingsProvider>(context, listen: false);
                    provider.setThemeMode(ThemeMode.system);
                    provider.setDynamicTheming(false);
                  }),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
