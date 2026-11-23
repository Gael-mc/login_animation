import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//C.1 Diálogo para recuperar la contraseña con Firebase
class ForgotPasswordDialog extends StatefulWidget {
  //Correo que ya estaba escrito en el Login (si había uno)
  final String initialEmail;

  const ForgotPasswordDialog({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final TextEditingController emailCtrl = TextEditingController(
    text: widget.initialEmail,
  );

  bool _isLoading = false;
  String? errorText;

  Future<void> _sendResetEmail() async {
    //Evitar doble toque mientras se envía
    if (_isLoading) return;

    final email = emailCtrl.text.trim();

    //C.2 Solo revisar que el correo no esté vacío
    if (email.isEmpty) {
      setState(() {
        errorText = 'Escribe tu correo';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      errorText = null;
    });

    try {
      //C.3 Firebase manda un correo real con el enlace para cambiar la contraseña
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _closeWithMessage();
    } on FirebaseAuthException catch (e) {
      //C.4 OWASP: si el correo no existe respondemos igual que si existiera,
      //para no revelar qué correos están registrados
      if (e.code == 'user-not-found') {
        _closeWithMessage();
        return;
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        errorText = switch (e.code) {
          'invalid-email' => 'El correo no tiene un formato válido',
          'network-request-failed' => 'Sin conexión. Revisa tu internet',
          _ => 'No se pudo enviar el correo. Intenta de nuevo',
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        errorText = 'No se pudo enviar el correo. Intenta de nuevo';
      });
    }
  }

  //C.5 Cerrar el diálogo y mostrar un mensaje general
  void _closeWithMessage() {
    if (!mounted) return;
    //Guardar el ScaffoldMessenger antes de cerrar el diálogo
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Si el correo está registrado, te llegará un enlace para '
          'restablecer tu contraseña. Revisa también la carpeta de spam.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Escribe tu correo y te enviaremos un enlace para crear una '
            'contraseña nueva.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'E-mail',
              errorText: errorText,
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }
}
