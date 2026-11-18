import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  //B.1 Dominio obligatorio: solo se registran correos institucionales
  static const String _domain = '@tecdesoftware.edu.mx';

  //B.2 Controladores de los campos
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  //B.3 En el Registro SÍ se muestran errores por campo (ayudan al usuario)
  String? emailError;
  String? passError;
  String? confirmError;
  //Error que regresa Firebase (correo ya usado, sin internet, etc.)
  String? firebaseError;

  //B.4 Correo con formato usuario@tecdesoftware.edu.mx
  bool isInstitutionalEmail(String email) {
    final re = RegExp(
      r'^[^\s@]+@tecdesoftware\.edu\.mx$',
      caseSensitive: false,
    );
    return re.hasMatch(email);
  }

  //B.5 Reglas de la contraseña: texto que se muestra -> ¿se cumple?
  Map<String, bool> passwordRules(String pass) {
    return {
      'Mínimo 8 caracteres': pass.length >= 8,
      'Una letra mayúscula (A-Z)': RegExp(r'[A-Z]').hasMatch(pass),
      'Una letra minúscula (a-z)': RegExp(r'[a-z]').hasMatch(pass),
      'Un número (0-9)': RegExp(r'[0-9]').hasMatch(pass),
      'Un símbolo (! @ # \$ % ...)': RegExp(r'[^A-Za-z0-9\s]').hasMatch(pass),
    };
  }

  //B.6 Traducir los códigos de FirebaseAuthException a mensajes claros
  String firebaseMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ese correo ya tiene una cuenta. Inicia sesión.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'Firebase considera que la contraseña es débil.';
      case 'operation-not-allowed':
        return 'El registro con correo no está habilitado en Firebase.';
      case 'network-request-failed':
        return 'Sin conexión con Firebase. Revisa tu internet.';
      default:
        return 'No se pudo crear la cuenta ($code).';
    }
  }

  Future<void> _onSignUp() async {
    //Evitar doble toque mientras se registra
    if (_isLoading) return;

    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    final confirm = confirmCtrl.text;

    //B.7 Validar los 3 campos antes de llamar a Firebase
    final allRulesOk = passwordRules(pass).values.every((ok) => ok);
    setState(() {
      emailError = isInstitutionalEmail(email)
          ? null
          : 'Usa tu correo institucional ($_domain)';
      passError = allRulesOk
          ? null
          : 'La contraseña no cumple todas las reglas';
      confirmError = confirm.isNotEmpty && confirm == pass
          ? null
          : 'Las contraseñas no coinciden';
      firebaseError = null;
    });
    if (emailError != null || passError != null || confirmError != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    try {
      //B.8 Registro real en Firebase Authentication
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      //Firebase inicia sesión solo al crear la cuenta; la cerramos
      //para que el usuario entre desde el Login (con el osito)
      await FirebaseAuth.instance.signOut();

      //B.9 Avisar al usuario y regresar al Login con el correo ya escrito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada! Ahora inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, email);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        firebaseError = firebaseMessage(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        firebaseError = 'No se pudo crear la cuenta. Intenta de nuevo.';
      });
    }
  }

  //Estilo común de los campos (igual que en el Login)
  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    String? error,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      errorMaxLines: 2,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rules = passwordRules(passCtrl.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add_alt_1, size: 72, color: Colors.blue),
              const SizedBox(height: 8),
              const Text(
                'Regístrate con tu correo institucional',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              //Correo institucional
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration(
                  hint: 'usuario$_domain',
                  icon: Icons.email,
                  error: emailError,
                ),
              ),
              const SizedBox(height: 10),

              //Contraseña
              TextField(
                controller: passCtrl,
                obscureText: _isObscure,
                //Redibujar para que las reglas se marquen mientras escribe
                onChanged: (_) => setState(() {}),
                decoration: _fieldDecoration(
                  hint: 'Contraseña',
                  icon: Icons.lock,
                  error: passError,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              //B.10 Reglas visibles: se ponen en verde conforme se cumplen
              ...rules.entries.map(
                (rule) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        rule.value
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: rule.value ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rule.key,
                        style: TextStyle(
                          color: rule.value
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              //Confirmar contraseña
              TextField(
                controller: confirmCtrl,
                obscureText: _isObscure,
                decoration: _fieldDecoration(
                  hint: 'Confirmar contraseña',
                  icon: Icons.lock_outline,
                  error: confirmError,
                ),
              ),
              const SizedBox(height: 16),

              //Mensaje de Firebase si el registro falla
              if (firebaseError != null) ...[
                Text(
                  firebaseError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              MaterialButton(
                onPressed: _onSignUp,
                height: 50,
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Crear cuenta',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
              const SizedBox(height: 10),

              //Regresar al Login sin registrarse
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }
}
