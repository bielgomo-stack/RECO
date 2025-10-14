
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(onPressed: () async { await auth.signOut(); Navigator.pushReplacementNamed(context, '/'); }, icon: const Icon(Icons.logout))
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: \${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No hay productos. Crea uno en Firestore.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final imageUrl = doc['imageUrl'] ?? '';
              final title = doc['title'] ?? 'Sin título';
              return ListTile(
                leading: Hero(tag: imageUrl + doc.id, child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover)),
                title: Text(title),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(
                    imageUrl: imageUrl,
                    details: List.from(doc['details'] ?? []),
                    docId: doc.id,
                    heroTag: imageUrl + doc.id,
                  )));
                },
              );
            },
          );
        },
      ),
    );
  }
}
