import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart'; 
import '../utils/app_formatters.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); 

  // Eliminamos _rolSeleccionado y _roles porque ahora es automático
  final TextEditingController _rutCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureText = true; 

  void _ejecutarLogin() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() => _isLoading = true);

    // Llamamos al servicio de autenticación (sin pasarle el rol)
    final usuarioLogueado = await AuthService().login(
      _rutCtrl.text.trim(), 
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return; 
    setState(() => _isLoading = false);

    if (usuarioLogueado != null) {
      // Si el login es exitoso, ruteamos según el rol de la base de datos
      switch (usuarioLogueado.rol) {
        case 'Cajero':
          context.go('/cajero');
          break;
        case 'Repartidor':
          context.go('/repartidor');
          break;
        case 'Administrador':
          context.go('/admin');
          break;
      }
    } else {
      // Si falla, mostramos error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('RUT o contraseña incorrectos.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _rutCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Usamos Stack para superponer el Post-it sobre el fondo
      body: Stack(
        children: [
          // 1. EL FONDO Y FORMULARIO (Tu código original modificado)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  Theme.of(context).scaffoldBackgroundColor,
                  colorScheme.primary.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView( 
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ESPACIO PARA EL LOGO
                          ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Iniciar Sesión",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ingresa tus credenciales para continuar",
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 40),

                          // CAMPO DE RUT (Selector de roles eliminado)
                          TextFormField(
                            controller: _rutCtrl,
                            decoration: InputDecoration(
                              labelText: "RUT del Empleado",
                              hintText: "Ej: 12345678-9",
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            inputFormatters: [RutInputFormatter()],
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'El RUT es obligatorio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // CONTRASEÑA
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscureText, 
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'La contraseña es requerida';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _ejecutarLogin(),
                          ),
                          const SizedBox(height: 32),

                          // BOTÓN DE INGRESO
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isLoading ? null : _ejecutarLogin,
                            child: _isLoading 
                                ? const SizedBox(
                                    height: 24, 
                                    width: 24, 
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                                  )
                                : const Text("Ingresar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. EL POST-IT DE TESTING (Ubicado en la esquina inferior derecha)
          Positioned(
            bottom: 30,
            right: 30,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow[200],
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.push_pin, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Mock Data (Testing)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    Divider(color: Colors.black26),
                    Text('👤 Cajero:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    Text('RUT: 21.936.615-9 | Pass: 123\n', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    
                    Text('🚚 Repartidor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    Text('RUT: 22.222.222-2 | Pass: 123\n', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    
                    Text('⚙️ Administrador:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    Text('RUT: 33.333.333-3 | Pass: 123', style: TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}