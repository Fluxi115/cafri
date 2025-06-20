import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

class FormularioPDF extends StatefulWidget {
  const FormularioPDF({super.key});

  @override
  State<FormularioPDF> createState() => _FormularioPDFState();
}

class _FormularioPDFState extends State<FormularioPDF> {
  // Controladores de texto para los campos principales
  final TextEditingController campoNombreCliente = TextEditingController();
  final TextEditingController campoOtraInfo = TextEditingController();
  final TextEditingController hablarcon = TextEditingController();
  final TextEditingController identificacion = TextEditingController();
  final TextEditingController actividadParaController = TextEditingController();
  final TextEditingController actividadTipoTareaController = TextEditingController();
  final TextEditingController descripcionTareaController = TextEditingController();
  final TextEditingController tipoSistemaController = TextEditingController();
  final TextEditingController tecnologiaController = TextEditingController();
  final TextEditingController modeloEvaporadorController = TextEditingController();
  final TextEditingController serieEvaporadorController = TextEditingController();
  final TextEditingController capacidadEvaporadorController = TextEditingController();
  final TextEditingController descripcionTrabajoRealizadoController = TextEditingController();

  // Listas para fotos de inicio, proceso y fin del servicio
  final List<FotoDescripcionItem> fotosMantenimientoInicio = [];
  final List<FotoDescripcionItem> fotosMantenimientoProceso = [];
  final List<FotoDescripcionItem> fotosMantenimientoFin = [];

  // Lista para imágenes extra de evaporadores/condensadores
  final List<File> imagenesEvaporadores = [];

  // Controladores y datos para firmas y nombres
  final SignatureController firmaTecnicoController = SignatureController(penStrokeWidth: 3, penColor: Colors.black);
  final SignatureController firmaRecibeController = SignatureController(penStrokeWidth: 3, penColor: Colors.black);
  Uint8List? firmaTecnico;
  Uint8List? firmaRecibe;
  String? nombreTecnico;
  String? nombreRecibe;
  final TextEditingController nombreTecnicoDialogController = TextEditingController();
  final TextEditingController nombreRecibeDialogController = TextEditingController();

  static int _folioGlobal = 2140669;
  late int folioActual;

  @override
  void initState() {
    super.initState();
    folioActual = _folioGlobal++;
  }

  // Método para mostrar el diálogo de firma y pedir nombre
  Future<void> _firmar(SignatureController controller, String titulo, TextEditingController nombreController, bool esTecnico) async {
    // Precargar el nombre si ya existe
    if (esTecnico && nombreTecnico != null) {
      nombreController.text = nombreTecnico!;
    } else if (!esTecnico && nombreRecibe != null) {
      nombreController.text = nombreRecibe!;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Signature(
                    controller: controller,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => controller.clear(),
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.isNotEmpty && nombreController.text.trim().isNotEmpty) {
                  final signature = await controller.toPngBytes();
                  Navigator.of(context).pop({
                    'firma': signature,
                    'nombre': nombreController.text.trim(),
                  });
                }
              },
              child: const Text('Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        if (esTecnico) {
          firmaTecnico = result['firma'];
          nombreTecnico = result['nombre'];
        } else {
          firmaRecibe = result['firma'];
          nombreRecibe = result['nombre'];
        }
      });
    }
  }

  // Método para eliminar la firma y el nombre
  void _eliminarFirma(bool esTecnico) {
    setState(() {
      if (esTecnico) {
        firmaTecnico = null;
        nombreTecnico = null;
        firmaTecnicoController.clear();
        nombreTecnicoDialogController.clear();
      } else {
        firmaRecibe = null;
        nombreRecibe = null;
        firmaRecibeController.clear();
        nombreRecibeDialogController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fechaActual = DateTime.now();
    final fechaFormateada =
        '${fechaActual.day.toString().padLeft(2, '0')}/'
        '${fechaActual.month.toString().padLeft(2, '0')}/'
        '${fechaActual.year} '
        '${fechaActual.hour.toString().padLeft(2, '0')}:'
        '${fechaActual.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Ejemplo PDF Tabla')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Información del cliente
              _seccionConTitulo(
                'Información del cliente',
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: campoNombreCliente,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del cliente',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: campoOtraInfo,
                            decoration: const InputDecoration(
                              labelText: 'Otra información',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hablar con:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextField(
                                controller: hablarcon,
                                decoration: const InputDecoration(
                                  labelText: 'Ingrese nombre con el que hablará',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tipo de tarea:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextField(
                                controller: identificacion,
                                decoration: const InputDecoration(
                                  labelText: 'Identificación Persona/Empresarial',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Información de las actividades
              _seccionConTitulo(
                'Información de las actividades',
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Para:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: actividadParaController,
                            decoration: const InputDecoration(
                              labelText: 'Escriba aquí',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Tipo de tarea:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: actividadTipoTareaController,
                            decoration: const InputDecoration(
                              labelText: 'Escriba aquí',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Fecha:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              fechaFormateada,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Descripción de la tarea:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: descripcionTareaController,
                            decoration: const InputDecoration(
                              labelText: 'Escriba aquí',
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Secciones de fotos
              _seccionConTitulo(
                'Formulario de mantenimiento preventivo y correctivo de aire acondicionado',
                FotoDescripcionLista(
                  encabezadoFoto: 'Foto',
                  encabezadoDescripcion: 'Descripción del inicio del servicio',
                  items: fotosMantenimientoInicio,
                  onAdd: (item) => setState(() => fotosMantenimientoInicio.add(item)),
                  onRemove: (idx) => setState(() => fotosMantenimientoInicio.removeAt(idx)),
                ),
              ),
              const SizedBox(height: 32),
              _seccionConTitulo(
                'Formulario de mantenimiento preventivo y correctivo de aire acondicionado',
                FotoDescripcionLista(
                  encabezadoFoto: 'Foto',
                  encabezadoDescripcion: 'Descripción del proceso del servicio',
                  items: fotosMantenimientoProceso,
                  onAdd: (item) => setState(() => fotosMantenimientoProceso.add(item)),
                  onRemove: (idx) => setState(() => fotosMantenimientoProceso.removeAt(idx)),
                ),
              ),
              const SizedBox(height: 32),
              _seccionConTitulo(
                'Formulario de mantenimiento preventivo y correctivo de aire acondicionado',
                FotoDescripcionLista(
                  encabezadoFoto: 'Foto',
                  encabezadoDescripcion: 'Descripción del fin del servicio',
                  items: fotosMantenimientoFin,
                  onAdd: (item) => setState(() => fotosMantenimientoFin.add(item)),
                  onRemove: (idx) => setState(() => fotosMantenimientoFin.removeAt(idx)),
                ),
              ),
              const SizedBox(height: 32),
              // Título para la tabla de condensadores/evaporadores
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Center(
                  child: Text(
                    'MODELO, SERIE, CAPACIDAD DE CONDENSADORES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              // Tabla de Modelo, Serie y Capacidad de evaporadores
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: const Color(0xFFE0E0E0),
                            child: const Center(
                              child: Text(
                                'Modelo',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: const Color(0xFFE0E0E0),
                            child: const Center(
                              child: Text(
                                'Serie',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            color: const Color(0xFFE0E0E0),
                            child: const Center(
                              child: Text(
                                'Capacidad de equipos',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: modeloEvaporadorController,
                              decoration: const InputDecoration(
                                hintText: 'Modelo de equipo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: serieEvaporadorController,
                              decoration: const InputDecoration(
                                hintText: 'Serie de equipo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: capacidadEvaporadorController,
                              decoration: const InputDecoration(
                                hintText: 'Capacidad de equipo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Opción para cargar, mostrar y eliminar varias imágenes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Cargar imagen o foto'),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final List<XFile> picked = await picker.pickMultiImage();
                      if (picked.isNotEmpty) {
                        setState(() {
                          imagenesEvaporadores.addAll(picked.map((x) => File(x.path)));
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (imagenesEvaporadores.isEmpty)
                    const Text('No hay imágenes agregadas.'),
                  if (imagenesEvaporadores.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imagenesEvaporadores.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                margin: const EdgeInsets.all(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    imagenesEvaporadores[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      imagenesEvaporadores.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              // Descripción del trabajo realizado
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Descripción del trabajo realizado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: descripcionTrabajoRealizadoController,
                        decoration: const InputDecoration(
                          hintText: 'Escriba aquí la descripción del trabajo realizado',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Tabla de firmas
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Firma del técnico',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                height: 100,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black26),
                                ),
                                child: firmaTecnico != null
                                    ? Image.memory(firmaTecnico!)
                                    : const Center(child: Text('Sin firma')),
                              ),
                              if (nombreTecnico != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    nombreTecnico!,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Firmar'),
                                    onPressed: () => _firmar(
                                      firmaTecnicoController,
                                      'Firma del técnico',
                                      nombreTecnicoDialogController,
                                      true,
                                    ),
                                  ),
                                  if (firmaTecnico != null)
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: const Text('Eliminar'),
                                      onPressed: () => _eliminarFirma(true),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Firma de quien recibe el servicio',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                height: 100,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black26),
                                ),
                                child: firmaRecibe != null
                                    ? Image.memory(firmaRecibe!)
                                    : const Center(child: Text('Sin firma')),
                              ),
                              if (nombreRecibe != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    nombreRecibe!,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Firmar'),
                                    onPressed: () => _firmar(
                                      firmaRecibeController,
                                      'Firma de quien recibe el servicio',
                                      nombreRecibeDialogController,
                                      false,
                                    ),
                                  ),
                                  if (firmaRecibe != null)
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: const Text('Eliminar'),
                                      onPressed: () => _eliminarFirma(false),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Aviso legal y ambiental de CAFRI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Text(
                  'En CAFRI, estamos comprometidos con la reducción del uso de papel y trabajamos continuamente para ser más amigables con el medio ambiente. '
                  'Nos esforzamos en la mejora constante y la actualización de nuestros sistemas para minimizar nuestro impacto ecológico.\n\n'
                  '(999) 102 1232 / (999) 490 1637   cafrimx.com\n\n'
                  'Este documento es propiedad de la empresa CAFRI COMPAÑÍA DE AIRE ACONDICIONADO Y FRIGORIFICOS DEL SURESTE S.A. DE C.V. con domicilio en Calle 59 K, 537 Cp. 97230 en la ciudad de Mérida, Yucatán, '
                  'por lo que queda prohibida la reproducción parcial o total de este documento y se tomarán acciones legales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para secciones con título
  Widget _seccionConTitulo(String titulo, Widget child) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}

// Widget para lista de fotos y descripciones dinámicas
class FotoDescripcionLista extends StatefulWidget {
  final String encabezadoFoto;
  final String encabezadoDescripcion;
  final List<FotoDescripcionItem> items;
  final void Function(FotoDescripcionItem) onAdd;
  final void Function(int) onRemove;

  const FotoDescripcionLista({
    super.key,
    required this.encabezadoFoto,
    required this.encabezadoDescripcion,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<FotoDescripcionLista> createState() => _FotoDescripcionListaState();
}

class _FotoDescripcionListaState extends State<FotoDescripcionLista> {
  Future<void> _agregarFoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      widget.onAdd(
        FotoDescripcionItem(
          file: File(picked.path),
          descripcionController: TextEditingController(),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Encabezado de la fila
        Row(
          children: [
            Expanded(
              child: Text(
                widget.encabezadoFoto,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                widget.encabezadoDescripcion,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Botón para agregar foto
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Agregar foto'),
            onPressed: _agregarFoto,
          ),
        ),
        const SizedBox(height: 12),
        // Lista de fotos y descripciones
        if (widget.items.isEmpty)
          const Text('No hay fotos agregadas.'),
        ...widget.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    item.file,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                // Descripción
                Expanded(
                  child: TextField(
                    controller: item.descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                // Botón eliminar
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => widget.onRemove(idx),
                  tooltip: 'Eliminar foto',
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class FotoDescripcionItem {
  final File file;
  final TextEditingController descripcionController;

  FotoDescripcionItem({
    required this.file,
    required this.descripcionController,
  });
}