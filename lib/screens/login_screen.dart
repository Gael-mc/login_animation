import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controla si la contraseña se ve o se oculta
  bool _isObscure = true;

  // Controlador de la máquina de estados de Rive
  StateMachineController? _controller;
  // Variables (inputs) de la animación
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  //3.2 Timer para detener la animación de mirar a los lados después de 3 segundos
  Timer? _typingDebonce;

  //2.1 crear variable para FocusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  //4.1 Controller email usuario 
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  //4.2 errores para mostrar en la ui 
  String? emailError;
  String? passError;

   // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }
  //4.4
  void _onLogin(){
    //recordar espacios en blanco accidentales 
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    //recalcular errores
    final emailTypeError = isValidEmail(email) ? null : 'Email inválido';
    final passTypeError = isValidPassword(pass) ? null : 'Password inválido';

    //4.5Para mostrar el cambio 
    setState(() {
      emailError = emailTypeError;
      passError = passTypeError;
    });

    //4.6 Cerrar el telcado y oso neutro 
    FocusScope.of(context).unfocus();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.7 Activar triggers
    if (emailTypeError == null && passTypeError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }                                                                            


  //2.2 Crear los oyentes (listeners)
  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          _numLook?.value = 50.0;
        }
      }
    });

    _passwordFocusNode.addListener(() {
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    //Obtiene el tamaño de la pantalla
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: screenSize.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login_bear.riv',
                    stateMachines: const ['Login Machine'],
                    //1.2 Vincular la animación
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      //1.3 Verificar que inició bien
                      if (_controller == null) return;
                      //Agregar el controlador al escenario
                      artboard.addController(_controller!);
                      //1.4 Vincular las variables
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                //Para separar elementos
                const SizedBox(height: 10),
                //Email
                TextField(
                  //4.8
                  controller: emailCtrl,
                  //2.3 Asignar el FocusNode al TextField
                  focusNode: _emailFocusNode,
                  //1.5 Vincular a campo de texto
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //No tapes los ojos al ver el email
                      // _isHandsUp!.change(false);
                    }
                    //Si isChecking es null
                    if (_isChecking == null) return;
                    //Activa el modo chismoso
                    _isChecking!.change(true);
                    //3.4 Implementar recorrido de miradas a los lados mientras se escribe
                    //Ajuste de limites del 0 a 100
                    //80 medida de calibración
                    final lookValue =
                        (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                    _numLook?.value = lookValue;

                    //3.5 Debounce: si vuelve a teclear, reinicia el contador
                    _typingDebonce?.cancel();
                    //Crear nuevo timer
                    _typingDebonce = Timer(const Duration(seconds: 3), () {
                      //Si se cierra la pantalla, termina la ejecución
                      if (!mounted) return;
                      //Mirada neutra
                      _isChecking?.change(false);
                    });
                  },
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: 'E-mail',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //Contraseña
                TextField(
                  controller: passCtrl,
                  //2.3 Asignar el FocusNode al TextField
                  focusNode: _passwordFocusNode,
                  //1.5 Vincular a campo de texto
                  onChanged: (value) {
                    if (_isChecking != null) {
                      //No actives el modo chismoso en contraseña
                      //_isChecking!.change(false);
                    }
                    //Si isHandsUp es null
                    if (_isHandsUp == null) return;
                    //Tapa los ojos
                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    errorText: passError,
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: screenSize.width,
                  child: const Text(
                    "Forgot password",
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),
                MaterialButton(
                  onPressed: _onLogin,
                  minWidth: screenSize.width,
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Liberar los FocusNodes
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    // Cancelar el timer si sigue activo
    _typingDebonce?.cancel();
    super.dispose();
  }
}
