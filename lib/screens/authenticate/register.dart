import 'package:brew_crew/services/auth.dart';
import 'package:brew_crew/shared/loading.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  final VoidCallback toggleView;

  const Register({super.key, required this.toggleView});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  String email = "";
  String password = "";
  int age = 0;
  String error = "";
  bool loading = false;

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Center(
            child: Scaffold(
              backgroundColor: const Color.fromARGB(255, 200, 240, 255),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      75,
                    ), // Half of width/height for full circle
                    child: Image.asset(
                      'assets/images/icon.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            onChanged: (val) => setState(() => email = val),
                            validator: (val) => val == null || val.isEmpty
                                ? "Enter an email"
                                : null,
                            decoration: InputDecoration(
                              hintText: "Email",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  30,
                                ), // very round = fun
                                borderSide: BorderSide(
                                  color: Colors.purple,
                                  width: .3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            onChanged: (val) => setState(() => password = val),
                            validator: (val) => val != null && val.length < 6
                                ? "Password must be at least 6 characters"
                                : null,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: "Password",
                              prefixIcon: const Icon(Icons.lock_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: Colors.purple,
                                  width: .3,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(() {
                              age = int.tryParse(val) ?? 0;
                            }),
                            validator: (val) {
                              final parsedAge = int.tryParse(val ?? '');
                              if (parsedAge == null || parsedAge <= 0) {
                                return "Enter a valid age";
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "Age",
                              prefixIcon: const Icon(Icons.cake_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  30,
                                ), // very round = fun
                                borderSide: BorderSide(
                                  color: Colors.purple,
                                  width: .3,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => loading = true);
                                final result = await _auth
                                    .registerWithEmailAndPassword(
                                      email,
                                      password,
                                      age,
                                    );
                                if (result == null) {
                                  setState(() {
                                    error =
                                        "Could not create user with those credentials";
                                    loading = false;
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[300],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Register",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: widget.toggleView,
                    child: const Text(
                      "Already have an account? Sign In",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
