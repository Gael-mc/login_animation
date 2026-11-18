import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  // 6.1 Parámetro clave: URL base de la API de Spring Boot (puerto 8090)
  // - Web / iOS Simulator / macOS / Windows: http://localhost:8090
  // - Emulador Android: 10.0.2.2 apunta a la PC (http://10.0.2.2:8090)
  // - Celular físico: usar la IP de tu computadora (ej. http://192.168.1.X:8090)
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8090';
    }
    return 'http://localhost:8090';
  }

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // Se guarda el Future para no repetir la petición en cada rebuild
  late Future<List<dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
  }

  // 6.2 Función para pedir la lista de productos al endpoint GET /products
  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('${ProductsScreen.baseUrl}/products'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Error al cargar productos de la API (${response.statusCode})',
      );
    }
  }

  // Reintentar la petición si falló
  void _retry() {
    setState(() {
      _productsFuture = fetchProducts();
    });
  }

  // Cerrar sesión en Firebase y regresar al Login
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos de Spring Boot'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (userEmail != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Sesión iniciada como: $userEmail'),
            ),
          Expanded(
            // 6.3 FutureBuilder: espera la respuesta de la API y dibuja el resultado
            child: FutureBuilder<List<dynamic>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                // Mientras responde el servidor, mostrar indicador de carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Si hubo un error de conexión
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 48),
                          const SizedBox(height: 10),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _retry,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(child: Text('No hay productos'));
                }

                // 6.4 Mostrar los elementos de la base de datos en una lista sencilla
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final category = product['category']?['category'];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${product['productId']}'),
                      ),
                      title: Text(product['name'].toString()),
                      subtitle: Text(
                        '${category ?? 'Sin categoría'} • Stock: ${product['stock']}',
                      ),
                      trailing: Text('\$${product['price']}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
