import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:definitiva/main.dart';

void main() {
  testWidgets('Verificar pantalla de bienvenida (Salí a descubrir Jujuy)', (WidgetTester tester) async {
    // Construye nuestra aplicación y dispara un frame.
    await tester.pumpWidget(const QuePaChaJujuyApp());

    // Verifica que el botón inicial y el título estén presentes en la pantalla de bienvenida.
    expect(find.text('Salí a descubrir Jujuy'), findsOneWidget);
    expect(find.text('¿Qué Pa Cha\nen Jujuy?'), findsOneWidget);
  });
}