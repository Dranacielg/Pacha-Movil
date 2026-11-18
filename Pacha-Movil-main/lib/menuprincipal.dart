import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  int _currentIndex = 0;

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

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) Navigator.pushNamed(context, '/colectivos');
    if (index == 2) Navigator.pushNamed(context, '/eventos');
    if (index == 3) Navigator.pushNamed(context, '/lugares');
  }

  // ══════════════════════════════════════════
  // EDITAR PERFIL
  // ══════════════════════════════════════════
  Future<void> _mostrarEditarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nombreCtrl = TextEditingController(text: user.displayName ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Editar perfil',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cuenta: ${user.email ?? ""}',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Nombre',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Tu nombre',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Color(0xFF2E334D),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.lock_reset, color: Colors.amberAccent),
                title: const Text('Cambiar contraseña',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                trailing:
                    const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.pop(ctx);
                  _cambiarPassword();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.email, color: Colors.tealAccent),
                title: const Text('Cambiar email',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                trailing:
                    const Icon(Icons.chevron_right, color: Colors.white38),
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
              backgroundColor: const Color(0xFFFF7F6C),
              foregroundColor: const Color(0xFF131622),
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
                  ScaffoldMessenger.of(ctx).showSnackBar(
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
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Cambiar contraseña',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: actualCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nuevaCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cambiar')),
        ],
      ),
    );

    if (ok != true) return;
    if (nuevaCtrl.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('La nueva contraseña debe tener al menos 6 caracteres')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Contraseña actualizada')));
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
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('Cambiar email',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nuevo email',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tu contraseña actual (para confirmar)',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cambiar')),
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
        content: Text('📧 Te enviamos un correo a la nueva dirección. Hacé clic en el enlace para confirmar el cambio.'),
        duration: Duration(seconds: 6),
    ));
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ HEADER ═══
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hola,',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_nombreUsuario 👋',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón Salir
                  TextButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: const Icon(Icons.logout,
                        size: 16, color: Color(0xFFFF7F6C)),
                    label: const Text('Salir',
                        style: TextStyle(
                            color: Color(0xFFFF7F6C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Botón Editar usuario
              TextButton.icon(
                onPressed: _mostrarEditarPerfil,
                icon: const Icon(Icons.edit,
                    size: 14, color: Colors.white70),
                label: const Text('Editar usuario',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: const Color(0xFF1E2235),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'QUE PA CHA EN JUJUY?',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),

              const Text(
                '¿Qué pinta hacer hoy?',
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 20),

              _buildCategoryCard(
                context,
                title: 'Colectivos y rutas',
                subtitle: 'Líneas, recorridos y como llegar a un destino?',
                imagePath: 'assets/colesyrutas.jpeg',
                route: '/colectivos',
              ),
              const SizedBox(height: 16),

              _buildCategoryCard(
                context,
                title: 'Eventos en la Ciudad',
                subtitle: 'Fiestas, Ferias y Recitales.',
                imagePath: 'assets/eventos.jpeg',
                route: '/eventos',
              ),
              const SizedBox(height: 16),

              _buildCategoryCard(
                context,
                title: 'Lugares Para Conocer',
                subtitle: 'Cine, Plazas, Compras, Restaurantes, y mas',
                imagePath: 'assets/lugaresconocer.jpeg',
                route: '/lugares',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCategoryCard(BuildContext context,
      {required String title,
      required String subtitle,
      required String imagePath,
      required String route}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                  color: Color(0xFF282D45),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(
                      child: Icon(Icons.image,
                          color: Colors.white24, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E334D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_outward,
                        size: 16, color: Color(0xFFFF7F6C)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161925),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF7F6C),
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus_outlined),
              label: 'Colectivos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Eventos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.place_outlined), label: 'Lugares'),
        ],
      ),
    );
  }
}