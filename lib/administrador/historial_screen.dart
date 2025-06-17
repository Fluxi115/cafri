import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  String? _selectedColaborador;
  List<Map<String, dynamic>> _colaboradores = [];

  @override
  void initState() {
    super.initState();
    _fetchColaboradores();
  }

  Future<void> _fetchColaboradores() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('rol', isEqualTo: 'colaborador')
        .get();
    final nuevosColaboradores = snapshot.docs
        .map((doc) => {
              'email': doc['email'],
              'name': doc['name'] ?? doc['email'],
            })
        .toList();

    setState(() {
      // Solo resetea si el colaborador seleccionado ya no existe
      if (_selectedColaborador != null &&
          !nuevosColaboradores.any((col) => col['email'] == _selectedColaborador)) {
        _selectedColaborador = null;
      }
      _colaboradores = nuevosColaboradores;
    });
  }

  Stream<QuerySnapshot> _getHistorialStream() {
    if (_selectedColaborador == null || _selectedColaborador!.isEmpty) {
      // No mostrar nada si no hay colaborador seleccionado
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('actividades')
        .where('colaborador', isEqualTo: _selectedColaborador)
        .where('estado', isEqualTo: 'terminada')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de actividades finalizadas'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedColaborador,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Selecciona un colaborador',
                border: OutlineInputBorder(),
              ),
              items: _colaboradores
                  .map((col) => DropdownMenuItem<String>(
                        value: col['email'],
                        child: Text(col['name']),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedColaborador = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedColaborador == null
                  ? const Center(
                      child: Text(
                        'Selecciona un colaborador para ver su historial.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _getHistorialStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No hay actividades finalizadas para este colaborador.',
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          );
                        }
                        final actividades = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: actividades.length,
                          itemBuilder: (context, index) {
                            final actividad = actividades[index].data() as Map<String, dynamic>;
                            final fecha = (actividad['fecha'] as Timestamp).toDate();
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.done_all, color: Colors.green),
                                title: Text(
                                  actividad['descripcion'] ?? 'Sin descripción',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy – HH:mm').format(fecha),
                                    ),
                                    if ((actividad['tipo'] ?? '').isNotEmpty)
                                      Text(
                                        'Tipo: ${actividad['tipo']}',
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                    if ((actividad['direccion_manual'] ?? '').isNotEmpty)
                                      Text(
                                        'Dirección: ${actividad['direccion_manual']}',
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}