
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'product_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool isLogin = true;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('RECO - Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: passController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 16),
              if (loading) const CircularProgressIndicator(),
              ElevatedButton(
                onPressed: () async {
                  setState(() => loading = true);
                  try {
                    if (isLogin) {
                      await auth.signIn(emailController.text.trim(), passController.text.trim());
                    } else {
                      await auth.signUp(emailController.text.trim(), passController.text.trim());
                    }
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
                  } finally {
                    setState(() => loading = false);
                  }
                },
                child: Text(isLogin ? 'Entrar' : 'Crear cuenta'),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? 'Crear cuenta' : 'Ya tengo cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
