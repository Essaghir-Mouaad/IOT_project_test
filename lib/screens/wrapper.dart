import 'package:brew_crew/models/user_model.dart';
import 'package:brew_crew/screens/authenticate/authenticate.dart';
import 'package:brew_crew/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the authenticated user from Provider
    final user = Provider.of<User?>(context);

    // user can be:
    //   null (not provided yet → show loading)
    //   null value (no user → show authenticate)
    //   User object (authenticated → show home)

    if (user == null) {
      // First check: if this is the initial state (haven't decided yet)
      // We can't distinguish between "loading" and "not authenticated" just by null
      // So we rely on the stream to provide initial data
      // Return Authenticate directly since Provider already waited for initial value
      return const Authenticate();
    }

    // User is authenticated, show home with device selection
    return Home(uid: user.uid);
  }
}
