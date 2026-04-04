
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/area.dart';

class Home extends StatelessWidget {
  final bool isAdmin;

  const Home({
    this.isAdmin = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Discover Jakarta'),
        actions: [
          // Hidden-ish admin button tucked in the corner
          IconButton(
            icon: const Icon(Icons.login_outlined, size: 18, color: Colors.grey),
            onPressed: () => context.push('/admin/login'),
          ),
        ],
      ),
      body:
      // Padding(
      //   padding:  const EdgeInsets.all(16),
      //   child: 
      //     Column(
      //       children: jakartaAreas.map((area) =>
      //         Expanded(
      //           child: AreaButton(area: area),
      //         ),
      //       ).toList(),
      //     )
      // )
        Center(
          child: SizedBox(
            width: 476,
            height: 476,
            child:
              Stack(
                alignment: Alignment.center,
                children: List.generate(jakartaAreas.length, (i) {
                  final area = jakartaAreas[i];
                  return _area(
                    area.name,
                    area.color,
                    _offsets[i],
                    '/pois/${area.id}${isAdmin ? '?admin=true' : ''}',
                    context,
                  );
                }),
              )
          ),
        )
    );
  }
}

extension HexColor on String {
  Color toColor() {
    var hexString = this;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

final List<Offset> _offsets = [
  Offset(0, 0),
  Offset(0, -162),
  Offset(0, 162),
  Offset(-162, 0),
  Offset(162, 0),
];

Widget _area(String text, String bgColor, Offset offset, String pushTo, BuildContext context) {
  return Transform.translate(
    offset: offset,
    child: ElevatedButton(
      onPressed: () => context.push(pushTo),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor.toColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        fixedSize: const Size(152, 152),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}