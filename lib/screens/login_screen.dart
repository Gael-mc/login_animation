import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;
  StateMachineController? _controller;

  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  Timer? _typingDebounce;

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        _isHandsUp?.value = false;
        _numLook?.value = 50.0;
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        _isHandsUp?.value = true;
      }
    });
  }

  void _onEmailFocused(bool isFocused) {
    if (_isChecking != null) {
      _isChecking!.value = isFocused;
    }
    if (_isHandsUp != null && isFocused) {
      _isHandsUp!.value = false;
    }
  }

  void _onPasswordFocused(bool isFocused) {
    if (_isHandsUp != null) {
      _isHandsUp!.value = isFocused;
    }
    if (_numLook != null) {
      _numLook!.value = isFocused ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _controller?.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    fit: BoxFit.contain,
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      if (_controller == null) return;

                      artboard.addController(_controller!);

                      _isChecking =
                          _controller?.findSMI('isChecking') as SMIBool?;
                      _isHandsUp =
                          _controller?.findSMI('isHandsUp') as SMIBool?;
                      _trigSuccess =
                          _controller?.findSMI('trigSuccess') as SMITrigger?;
                      _trigFail =
                          _controller?.findSMI('trigFail') as SMITrigger?;
                      _numLook = _controller?.findSMI('numLook') as SMINumber?;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  focusNode: _emailFocusNode,
                  onTap: () => _onEmailFocused(true),
                  onChanged: (value) {
                    _onEmailFocused(true);
                    _numLook?.value = (value.length / 80.0 * 100.0)
                        .clamp(0.0, 100.0)
                        .toDouble();

                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) return;
                      _isChecking?.value = false;
                    });
                  },
                  onEditingComplete: () => _onEmailFocused(false),
                  decoration: InputDecoration(
                    hintText: 'E-mail',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  focusNode: _passwordFocusNode,
                  obscureText: _isObscure,
                  onTap: () => _onPasswordFocused(true),
                  onChanged: (_) => _onPasswordFocused(true),
                  onEditingComplete: () => _onPasswordFocused(false),
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                        _onPasswordFocused(!_isObscure);
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_trigSuccess == null || _trigFail == null) {
                        _trigFail?.fire();
                        return;
                      }

                      if (_isChecking != null) {
                        _isChecking!.value = true;
                      }

                      Future.delayed(const Duration(milliseconds: 600), () {
                        _trigSuccess!.fire();
                        if (_isChecking != null) {
                          _isChecking!.value = false;
                        }
                      });
                    },
                    child: const Text('Iniciar sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
