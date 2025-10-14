
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';

class ProductDetailScreen extends StatefulWidget {
  final String imageUrl;
  final List<dynamic> details;
  final String docId;
  final String heroTag;

  const ProductDetailScreen({
    Key? key,
    required this.imageUrl,
    required this.details,
    required this.docId,
    required this.heroTag,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late List<Map<String, dynamic>> zones;
  Rect? currentRect;
  Offset? dragStart;
  GlobalKey imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    zones = widget.details.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> updateZones() async {
    await FirebaseFirestore.instance.collection('products').doc(widget.docId).update({'details': zones});
  }

  Future<void> openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
    }
  }

  void startDrag(Offset localPos) {
    final box = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final dx = localPos.dx.clamp(0.0, size.width);
    final dy = localPos.dy.clamp(0.0, size.height);
    setState(() { dragStart = Offset(dx, dy); currentRect = Rect.fromLTWH(dx, dy, 0, 0); });
  }

  void updateDrag(Offset localPos) {
    if (dragStart == null) return;
    final box = imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final dx = localPos.dx.clamp(0.0, size.width);
    final dy = localPos.dy.clamp(0.0, size.height);
    setState(() { currentRect = Rect.fromPoints(dragStart!, Offset(dx, dy)); });
  }

  void endDrag() {
    if (currentRect == null) return;
    final r = currentRect!;
    setState(() {
      zones.add({
        'title': 'Nueva zona',
        'link': '',
        'rect': {'left': r.left, 'top': r.top, 'right': r.right, 'bottom': r.bottom}
      });
      currentRect = null; dragStart = null;
    });
    updateZones();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zona creada')));
  }

  void editZone(int index) {
    final titleController = TextEditingController(text: zones[index]['title']);
    final linkController = TextEditingController(text: zones[index]['link']);

    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Editar Zona'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Título')),
        TextField(controller: linkController, decoration: const InputDecoration(labelText: 'Enlace')),
      ]),
      actions: [
        TextButton(onPressed: () async {
          final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Eliminar esta zona?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
          )) ?? false;
          if (confirm) {
            setState(() => zones.removeAt(index));
            await updateZones();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zona eliminada')));
          }
        }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ElevatedButton(onPressed: () async {
          setState(() { zones[index]['title'] = titleController.text; zones[index]['link'] = linkController.text; });
          await updateZones();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zona actualizada')));
        }, child: const Text('Guardar')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Producto')),
      body: LayoutBuilder(builder: (context, constraints) {
        return GestureDetector(child: Stack(children: [
          Positioned.fill(child: Center(child: InteractiveViewer(child: AspectRatio(aspectRatio: 1, child: Stack(key: imageKey, children: [
            Positioned.fill(child: Hero(tag: widget.heroTag, child: Image.network(widget.imageUrl, fit: BoxFit.cover))),
            for (int i=0;i<zones.length;i++)
              if (zones[i]['rect']?['left']!=null && zones[i]['rect']?['top']!=null && zones[i]['rect']?['right']!=null && zones[i]['rect']?['bottom']!=null)
                Positioned(left: (zones[i]['rect']['left'] as num).toDouble(), top: (zones[i]['rect']['top'] as num).toDouble(), width: ((zones[i]['rect']['right'] as num)-(zones[i]['rect']['left'] as num)).toDouble(), height: ((zones[i]['rect']['bottom'] as num)-(zones[i]['rect']['top'] as num)).toDouble(), child: GestureDetector(onTap: () { final link = zones[i]['link'] ?? ''; if ((link as String).isNotEmpty) openLink(link); else editZone(i); }, child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.orange, width: 2), color: Colors.orange.withOpacity(0.15)), child: Center(child: Container(padding: const EdgeInsets.all(4), color: Colors.white.withOpacity(0.7), child: Text(zones[i]['title'] ?? '', textAlign: TextAlign.center))), ), ), ),
            if (currentRect!=null) Positioned(left: currentRect!.left, top: currentRect!.top, width: currentRect!.width, height: currentRect!.height, child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent, width: 2), color: Colors.blueAccent.withOpacity(0.15)),),),
            Positioned.fill(child: Listener(onPointerDown: (e) { startDrag(e.localPosition); }, onPointerMove: (e) { updateDrag(e.localPosition); }, onPointerUp: (e) { endDrag(); }, child: Container(color: Colors.transparent),)),
          ]))))),
        ]));
      }),
      floatingActionButton: Builder(builder: (context) {
        return FloatingActionButton(
          child: const Icon(Icons.edit),
          onPressed: () {
            // Only allow admin to edit: check in cloud rules; UI could also hide controls.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mantén pulsado y arrastra sobre la imagen para crear una zona.')));
          },
        );
      }),
    );
  }
}
