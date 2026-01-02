import 'package:agri_marketplace_app/screen/home.dart';
import 'package:agri_marketplace_app/screen/search.dart';
import 'package:flutter/material.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required Map quantities, required Map orderItems, required bool showOrderPlacedMessage});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
final List<Widget> _pages =[
  HomePage(userName: '', farmerId: '', buyerId: '',),
  SearchPage(),

  
];

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _pages[_currentIndex],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.red,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'HomePage',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Searchpage',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'ProfilePage',
        ), 
      ],
    ),
  );
}
}
