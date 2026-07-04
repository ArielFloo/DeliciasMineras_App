import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>(); 

  // Selector de perfiles y contraseña temporal
  String _rolSeleccionado = 'Cajero';
  final List<String> _roles = ['Cajero', 'Repartidor', 'Administrador'];
  final TextEditingController _passwordCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureText = true; 

  void _ejecutarLogin() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() => _isLoading = true);

    // Simulamos un pequeño tiempo de carga para que se vea la animación del botón
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return; 
    setState(() => _isLoading = false);

    // Validación temporal con clave estática
    if (_passwordCtrl.text.trim() == '1234') {
      switch (_rolSeleccionado) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Credenciales incorrectas (Prueba con la clave 1234)'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
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

                      // SELECTOR DE ROLES
                      DropdownButtonFormField<String>(
                        value: _rolSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Perfil de Usuario',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _roles.map((String rol) {
                          return DropdownMenuItem<String>(
                            value: rol,
                            child: Text(rol),
                          );
                        }).toList(),
                        onChanged: (String? nuevoValor) {
                          setState(() {
                            _rolSeleccionado = nuevoValor!;
                          });
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

                      // BOTÓN DE REGISTRO INACTIVO
                      TextButton(
                        onPressed: () {
                          // TODO: Implementar lógica de registro futuro
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Función de registro próximamente...')),
                          );
                        },
                        child: Text(
                          "Registrar nuevo usuario", 
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}