import 'package:finalltmcb/Controllers/UserController.dart';
import 'package:finalltmcb/Provider/UserProvider.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Initialize focus nodes and controllers
  final FocusNode _chatIdFocusNode =
      FocusNode(); // Changed from _emailFocusNode
  final FocusNode _passwordFocusNode = FocusNode();
  final TextEditingController _chatIdController =
      TextEditingController(); // Changed from _emailController
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final UserController _userController = UserController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _handleLogin() async {
    if (_chatIdController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ thông tin';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = await _userController.login(
        _chatIdController.text,
        _passwordController.text,
      );

      if (mounted) {
        // Store user in provider
        UserProvider().setUser(user);

        // Set success message
        setState(() {
          _successMessage = 'Đăng nhập thành công!';
        });

        // Clear form
        _chatIdController.clear();
        _passwordController.clear();

        // Navigate after brief delay to show success message
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/chat',
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        _errorMessage = errorMsg;

        // Focus the appropriate field based on the error
        if (errorMsg.contains('Chat ID không tồn tại')) {
          _chatIdFocusNode.requestFocus();
        } else if (errorMsg.contains('Sai mật khẩu')) {
          // Keep what the user typed in the username field but focus on password
          _passwordController.clear();
          _passwordFocusNode.requestFocus();
        } else {
          // For other errors, default to focusing the username field
          _chatIdFocusNode.requestFocus();
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
  void initState() {
    super.initState();
    // Add any additional initialization if needed
  }

  @override
  void dispose() {
    // Clean up the controllers and focus nodes
    _chatIdFocusNode.dispose(); // Changed from _emailFocusNode
    _passwordFocusNode.dispose();
    _chatIdController.dispose(); // Changed from _emailController
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Đăng nhập',
            style: TextStyle(
              color: AppColors.messengerBlue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          TextFormField(
            focusNode: _chatIdFocusNode, // Changed from _emailFocusNode
            controller: _chatIdController, // Changed from _emailController
            keyboardType:
                TextInputType.text, // Changed from TextInputType.emailAddress
            textInputAction: TextInputAction.next,
            style: TextStyle(color: Colors.black),
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            onChanged: (value) {
              // Clear error message when user starts typing
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Tài khoản', // Changed from 'Email'
              hintStyle: TextStyle(color: AppColors.lightGrey),
              prefixIcon: Icon(
                Icons.person_outline, // Changed from Icons.email_outlined
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
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            focusNode: _passwordFocusNode,
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: Colors.black),
            onChanged: (value) {
              // Clear error message when user starts typing
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Mật khẩu',
              hintStyle: TextStyle(color: AppColors.lightGrey),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: AppColors.lightGrey,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.lightGrey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              enabledBorder: OutlineInputBorder(
                // Thêm enabledBorder
                borderSide: BorderSide(
                    color: AppColors.lightGrey), // Màu đen khi chưa focus
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.messengerBlue),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            ),
          ),
          SizedBox(height: 16),
          // Error message in red
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          // Success message in green
          if (_successMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.messengerBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Quên mật khẩu',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.messengerBlue,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bạn mới biết đến facebug? ',
                style: TextStyle(color: Colors.black),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context,
                      '/signup'); // Changed from Router.navigate to Navigator.pushNamed
                },
                child: Text(
                  'Đăng ký',
                  style: TextStyle(
                    color: AppColors.messengerBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
