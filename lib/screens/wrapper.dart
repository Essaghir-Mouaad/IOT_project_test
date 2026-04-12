// import 'package:brew_crew/models/user.dart';
// import 'package:brew_crew/screens/authenticate/authenticate.dart';
import 'package:brew_crew/screens/home/home.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // return home or authenticate widget

    // final user = Provider.of<User?>(context);

    // if (user == null) {
    //   return const Authenticate();
    // }
    // print(user);

    return const Home();
  }
}
