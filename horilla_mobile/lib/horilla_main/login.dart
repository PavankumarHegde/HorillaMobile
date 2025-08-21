import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late StreamSubscription subscription;
  var isDeviceConnected = false;
  bool isAlertSet = false;
  bool _passwordVisible = false;
  final TextEditingController serverController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  double horizontalMargin = 0.0;
  Timer? _notificationTimer;


  @override
  void initState() {
    super.initState();
    getConnectivity();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      double screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        horizontalMargin = screenWidth * 0.1;
      });
    });
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (isAuthenticated) {
        fetchNotifications();
        unreadNotificationsCount();
      } else {
        timer.cancel();
        _notificationTimer = null;
      }
    });
  }



  Future<void> _login() async {
    String serverAddress = serverController.text.trim();
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();
    String url = '$serverAddress/api/auth/login/';

    try {
      http.Response response = await http.post(
        Uri.parse(url),
        body: {'username': username, 'password': password},
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        var token = responseBody['access'] ?? '';

        var employeeId = responseBody['employee']?['id'] ?? 0;
        var companyId = responseBody['company_id'] ?? 0;
        bool face_detection = responseBody['face_detection'] ?? false;
        bool geo_fencing = responseBody['geo_fencing'] ?? false;
        var face_detection_image = responseBody['face_detection_image']?.toString() ?? '';


        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("typed_url", serverAddress);
        await prefs.setString("face_detection_image", face_detection_image);
        await prefs.setBool("face_detection", face_detection);
        await prefs.setBool("geo_fencing", geo_fencing);
        await prefs.setInt("employee_id", employeeId);
        await prefs.setInt("company_id", companyId);

        isAuthenticated = true;
        _startNotificationTimer();
        prefetchData();

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection timeout'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid server address'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void getConnectivity() {
    // subscription = InternetConnectionChecker().onStatusChange.listen((status) {
    //   setState(() {
    //     isDeviceConnected = status == InternetConnectionStatus.connected;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    final String? serverAddress =
    ModalRoute.of(context)?.settings.arguments as String?;

    if (serverAddress != null && serverController.text.isEmpty) {
      serverController.text = serverAddress;
    }

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.42,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.red,
                ),
                alignment: Alignment.bottomCenter,
                child: Center(
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 15),
                      child: Image.asset(
                        'Assets/horilla-logo.png',
                        height: MediaQuery.of(context).size.height * 0.11,
                        width: MediaQuery.of(context).size.height * 0.11,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.3,
                  left: horizontalMargin,
                  right: horizontalMargin,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(20.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          _buildTextFormField(
                            'Server Address',
                            serverController,
                            false,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          _buildTextFormField(
                            'Email',
                            usernameController,
                            false,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          _buildTextFormField(
                            'Password',
                            passwordController,
                            true,
                            _passwordVisible,
                                () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.0),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      String label,
      TextEditingController controller,
      bool isPassword, [
        bool? passwordVisible,
        VoidCallback? togglePasswordVisibility,
      ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !(passwordVisible ?? false) : false,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: const BorderSide(width: 1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.015,
              horizontal: controller.text.isNotEmpty ? 16.0 : 12.0,
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                passwordVisible! ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: togglePasswordVisibility,
            )
                : null,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}
