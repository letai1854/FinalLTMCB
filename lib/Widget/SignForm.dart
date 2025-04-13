import 'package:finalltmcb/Controllers/UserController.dart';
import 'package:finalltmcb/Widget/SuccessMessage.dart';
import 'package:finalltmcb/constants/colors.dart';
import 'package:flutter/material.dart';

class SignForm extends StatefulWidget {
  const SignForm({Key? key}) : super(key: key);

  @override
  State<SignForm> createState() => _SignFormState();
}

class _SignFormState extends State<SignForm> {
  final FocusNode _emailFocusNode = FocusNode(); // Keep as username field
  final FocusNode _passwordFocusNode = FocusNode();
  final TextEditingController _emailController =
      TextEditingController(); // Keep as username field
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  // Removed name, address, re-password controllers and focus nodes
  // Removed _isRePasswordVisible

  final UserController _userController =
      UserController(); // Assuming this is still needed for signup logic
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleSignup() async {
    print('Username (Email): ${_emailController.text}');
    print('Password: ${_passwordController.text}');

    // Validate fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ Username và Mật khẩu';
      });
      return;
    }

    // Removed password matching validation

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Removed userData map creation

      // Call register method with email (as chatId) and password
      await _userController.register(
          _emailController.text, _passwordController.text);

      // Show success message and navigate
      // Assuming successful registration if no exception is thrown

      if (mounted) {
        // Clear input fields
        _emailController.clear();
        _passwordController.clear();
        // Removed clearing for name, address, re-password

        SuccessMessage.show(
          context,
          title: 'Đăng ký thành công!',
          duration: const Duration(seconds: 2),
          onDismissed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        // Extract clean error message
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        _errorMessage = errorMsg;

        // Show specific message for email duplicate
        if (errorMsg.contains('Email đã tồn tại')) {
          _emailFocusNode.requestFocus(); // Focus email field
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // Removed disposal for name, address, re-password
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGrey.withOpacity(0.3), // Màu shadow với độ trong suốt
            spreadRadius: 1, // Độ lan rộng của shadow
            blurRadius: 10, // Độ mờ của shadow
            offset: Offset(0, 0), // Vị trí shadow (x,y)
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Đăng ký',
              style: TextStyle(
                color: AppColors.messengerBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: double.infinity, height: 20),
            TextFormField(
              focusNode: _emailFocusNode,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: Colors.black),
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              onFieldSubmitted: (_) {
                // Move focus to password field on submit
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
              decoration: InputDecoration(
                hintText: 'Username (Email)', // Updated hint text
                hintStyle: TextStyle(color: AppColors.lightGrey),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.lightGrey,
                ),
                enabledBorder: OutlineInputBorder(
                  // Thêm enabledBorder
                  borderSide: BorderSide(
                      color: AppColors.lightGrey), // Màu đen khi chưa focus
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.messengerBlue),
                ),
              ),
            ),
            // Removed Name and Address TextFormFields and SizedBoxes
            SizedBox(width: double.infinity, height: 10),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              keyboardType: TextInputType.text,
              // Change textInputAction to done or send the form
              textInputAction: TextInputAction.done,
              obscureText: !_isPasswordVisible,
              style: TextStyle(color: Colors.black),
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              // Trigger signup when submitted from password field
              onFieldSubmitted: (_) => _isLoading ? null : _handleSignup(),
              decoration: InputDecoration(
                hintText: 'Mật khẩu',
                hintStyle: TextStyle(color: AppColors.lightGrey),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColors.lightGrey,
                ),
                suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.lightGrey,
                    )),
                enabledBorder: OutlineInputBorder(
                  // Thêm enabledBorder
                  borderSide: BorderSide(
                      color: AppColors.lightGrey), // Màu đen khi chưa focus
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.messengerBlue),
                ),
              ),
            ),
            // Removed Re-enter Password TextFormField and SizedBox
            SizedBox(
                width: double.infinity,
                height: 10), // Keep one SizedBox before error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(width: double.infinity, height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppColors.messengerBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Đăng ký',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
