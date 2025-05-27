import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:catchmate/pages/feed_page.dart';
import 'package:catchmate/pages/upload_page.dart';
import 'package:catchmate/pages/profile_page.dart';
import 'package:catchmate/pages/map_page_osm.dart';
import 'package:catchmate/pages/search_page.dart';
import 'package:catchmate/pages/coach_page.dart';
import 'package:catchmate/pages/tournament_page.dart';
import 'package:catchmate/pages/setup_swipe_page.dart';
import 'package:catchmate/pages/classifieds_page.dart';
import 'package:catchmate/pages/admin_dashboard.dart';
import 'package:catchmate/pages/group_page.dart';
import 'package:catchmate/pages/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const FeedPage(),
    const UploadPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CatchMate'),
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) {
            switch (value) {
              case 'Map':
                _navigateToPage(const MapPage());
                break;
              case 'Turniere':
                _navigateToPage(const TournamentPage());
                break;
              case 'Coach':
                _navigateToPage(const CoachPage());
                break;
              case 'KöderTinder':
                _navigateToPage(const SetupSwipePage());
                break;
              case 'Anzeigen':
                _navigateToPage(const ClassifiedsPage());
                break;
              case 'Suche':
                _navigateToPage(const SearchPage());
                break;
              case 'Gruppen':
                _navigateToPage(const GroupPage());
                break;
              case 'Admin':
                _navigateToPage(const AdminDashboard());
                break;
              case 'Logout':
                _logout();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Map', child: Text('Karte')),
            const PopupMenuItem(value: 'Turniere', child: Text('Turniere')),
            const PopupMenuItem(value: 'Coach', child: Text('KI-Coach')),
            const PopupMenuItem(value: 'KöderTinder', child: Text('KöderTinder')),
            const PopupMenuItem(value: 'Anzeigen', child: Text('Kleinanzeigen')),
            const PopupMenuItem(value: 'Suche', child: Text('Suche')),
            const PopupMenuItem(value: 'Gruppen', child: Text('Gruppen')),
            const PopupMenuItem(value: 'Admin', child: Text('Adminbereich')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'Logout', child: Text('Logout')),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Hochladen'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
