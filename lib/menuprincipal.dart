import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  int _currentIndex = 0;

  // ══════════════════════════════════════════
  // CAMBIÁ ESTA RUTA POR LA FOTO DEL HEADER
  // ══════════════════════════════════════════
  static const String _headerImagePath = 'assets/header_jujuy.jpeg';

  static const Color _bgColor = Color(0xFFF2F4FC);
  static const Color _headerBlue = Color(0xFF2357B8);
  static const Color _headerDarkBlue = Color(0xFF173B82);
  static const Color _primaryPurple = Color(0xFF6B35D9);

  String get _nombreUsuario {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.email == 'admin@pacha.com') return 'Admin';

    final nombre = user?.displayName?.trim();
    if (nombre != null && nombre.isNotEmpty) {
      return nombre.split(' ').first;
    }

    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'vecino';
  }

  Future<void> _irARuta(String routeName, {int? navIndex}) async {
    if (!mounted) return;
    if (navIndex != null) {
      setState(() => _currentIndex = navIndex);
    }
    try {
      await Navigator.pushNamed(context, routeName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruta no configurada ($routeName): $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _currentIndex = 0);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    if (index == 1) {
      _irARuta('/colectivos', navIndex: 1);
    } else if (index == 2) {
      _irARuta('/eventos', navIndex: 2);
    } else if (index == 3) {
      _irARuta('/lugares', navIndex: 3);
    }
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ══════════════════════════════════════════
  // EDITAR PERFIL
  // ══════════════════════════════════════════
  Future<void> _mostrarEditarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay sesión activa')),
      );
      return;
    }

    final nombreCtrl = TextEditingController(text: user.displayName ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Editar perfil',
          style: TextStyle(color: _headerDarkBlue, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cuenta: ${user.email ?? ""}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nombre',
                style: TextStyle(color: Colors.black87, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nombreCtrl,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Tu nombre',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: _bgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.black12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset, color: _primaryPurple),
                title: const Text(
                  'Cambiar contraseña',
                  style: TextStyle(color: Colors.black87, fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () {
                  Navigator.pop(ctx);
                  _cambiarPassword();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email, color: _headerBlue),
                title: const Text(
                  'Cambiar email',
                  style: TextStyle(color: Colors.black87, fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                onTap: () {
                  Navigator.pop(ctx);
                  _cambiarEmail();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final nuevoNombre = nombreCtrl.text.trim();
              try {
                await user.updateDisplayName(
                    nuevoNombre.isEmpty ? null : nuevoNombre);
                await user.reload();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Nombre actualizado')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarPassword() async {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(color: _headerDarkBlue, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: actualCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                labelStyle: TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nuevaCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                labelStyle: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (nuevaCtrl.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La nueva contraseña debe tener al menos 6 caracteres'),
          ),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: actualCtrl.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(nuevaCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Contraseña actualizada')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Error al cambiar contraseña';
      if (e.code == 'wrong-password') {
        msg = 'La contraseña actual es incorrecta';
      }
      if (e.code == 'weak-password') {
        msg = 'La nueva contraseña es muy débil';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _cambiarEmail() async {
    final passCtrl = TextEditingController();
    final emailCtrl = TextEditingController(
        text: FirebaseAuth.instance.currentUser?.email ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Cambiar email',
          style: TextStyle(color: _headerDarkBlue, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Nuevo email',
                labelStyle: TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Tu contraseña actual (para confirmar)',
                labelStyle: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final nuevoEmail = emailCtrl.text.trim();
    if (nuevoEmail.isEmpty || !nuevoEmail.contains('@')) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Email inválido')));
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: passCtrl.text);
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(nuevoEmail);
      await user.reload();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '📧 Te enviamos un correo a la nueva dirección. Hacé clic en el enlace para confirmar el cambio.'),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Error al cambiar email';
      if (e.code == 'wrong-password') {
        msg = 'La contraseña actual es incorrecta';
      }
      if (e.code == 'invalid-email') {
        msg = 'El email no es válido';
      }
      if (e.code == 'email-already-in-use') {
        msg = 'Ese email ya está registrado';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(context),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverlayCategoryCard(
                    context,
                    title: 'Colectivos y rutas',
                    subtitle: 'Líneas, horarios y recorridos',
                    imagePath: 'assets/colesyrutas.jpeg',
                    route: '/colectivos',
                    navIndex: 1,
                  ),
                  const SizedBox(height: 14),
                  _buildOverlayCategoryCard(
                    context,
                    title: 'Eventos en la Ciudad',
                    subtitle: 'Fiestas, Ferias y Recitales',
                    imagePath: 'assets/eventos.jpeg',
                    route: '/eventos',
                    navIndex: 2,
                  ),
                  const SizedBox(height: 14),
                  _buildOverlayCategoryCard(
                    context,
                    title: 'Lugares para Conocer',
                    subtitle: 'Cerros, quebradas y miradores',
                    imagePath: 'assets/lugaresconocer.jpeg',
                    route: '/lugares',
                    navIndex: 3,
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ══════════════════════════════════════════
  // ENCABEZADO CON FOTO + OLA INFERIOR LIMPIA
  // ══════════════════════════════════════════
  Widget _buildTopHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      width: double.infinity,
      height: topPadding + 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/banne_heroes.jpg' ,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_headerBlue, _headerDarkBlue],
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 44),
              child: const Text(
                'Espacio reservado para la foto del encabezado',
                style: TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.black.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),

          // Ola inferior contenida dentro del alto total del encabezado
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 36,
            child: CustomPaint(
              painter: _HeaderWavePainter(color: _bgColor),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            top: topPadding + 10,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Qué pasa en Jujuy?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No tenés notificaciones nuevas'),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.notifications_none_rounded,
                                color: Colors.white, size: 23),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4D4F),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(Icons.menu_rounded,
                          color: Colors.white, size: 25),
                      onSelected: (value) async {
                        if (value == 'editar') {
                          await _mostrarEditarPerfil();
                        } else if (value == 'salir') {
                          await _cerrarSesion();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: _headerBlue),
                              SizedBox(width: 8),
                              Text('Editar perfil'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'salir',
                          child: Row(
                            children: [
                              Icon(Icons.logout,
                                  size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Salir'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  'Hola, $_nombreUsuario · ¿Qué podemos hacer hoy?',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21.5,
                    fontWeight: FontWeight.w800,
                    height: 1.14,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imagePath,
    required String route,
    required int navIndex,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _irARuta(route, navIndex: navIndex),
      child: Container(
        height: 118,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _headerDarkBlue,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image,
                      color: Colors.white38, size: 36),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final navItems = [
      (icon: Icons.home_outlined, label: 'Inicio'),
      (icon: Icons.directions_bus_outlined, label: 'Colectivos'),
      (icon: Icons.calendar_today_outlined, label: 'Eventos'),
      (icon: Icons.place_outlined, label: 'Lugares'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onItemTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 21,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _HeaderWavePainter extends CustomPainter {
  final Color color;

  const _HeaderWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.25, h * 0.08, w * 0.52, h * 0.52)
      ..quadraticBezierTo(w * 0.78, h * 0.96, w, h * 0.30)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HeaderWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}