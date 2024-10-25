import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  String? _selectedRole;
  String? _selectedClassTeacher;
  String? _selectedCourse;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;

  List<String> _classTeachers = [];
  List<String> _courses = ['MCA', 'MSc', 'BTech'];
  bool _isLoading = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Map<String, IconData> _courseIcons = {
    'MCA': FontAwesomeIcons.laptopCode,
    'MSc': FontAwesomeIcons.flask,
    'BTech': FontAwesomeIcons.microchip,
  };

  @override
  void initState() {
    super.initState();
    _loadClassTeachers();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadClassTeachers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'class_teacher')
          .get();

      setState(() {
        _classTeachers =
            querySnapshot.docs.map((doc) => doc['name'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading class teachers: $e');
      setState(() {
        _classTeachers = ['Error loading teachers'];
        _isLoading = false;
      });
    }
  }

  String _generateId(String prefix) {
    Random random = Random();
    String numbers = '';
    for (int i = 0; i < 6; i++) {
      numbers += random.nextInt(10).toString();
    }
    return '$prefix$numbers';
  }

  void _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        String generatedId =
            _generateId(_selectedRole == 'Student' ? 'S' : 'T');

        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        Map<String, dynamic> userData = {
          'uid': userCredential.user!.uid,
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'role': _selectedRole,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (_selectedRole == 'Student') {
          userData['studentId'] = generatedId;
          userData['classTeacher'] = _selectedClassTeacher;
          userData['course'] = _selectedCourse;
        } else {
          userData['teacherId'] = generatedId;
          userData['department'] = _departmentController.text;
        }

        await FirebaseFirestore.instance
            .collection('registration_requests')
            .add(userData);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Registration request submitted successfully. Your ID is $generatedId')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit registration request: $e')),
        );
      }

      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.indigo.shade600,
              Colors.blue.shade500
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    SizedBox(height: 40),
                    _selectedRole == null
                        ? _buildRoleSelection()
                        : _buildRegistrationForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Text(
      'Register',
      style: GoogleFonts.poppins(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRoleSelection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Select your role',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRoleButton('Student', FontAwesomeIcons.userGraduate),
                  _buildRoleButton(
                      'Teacher', FontAwesomeIcons.chalkboardTeacher),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role, IconData icon) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedRole = role),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue.shade600,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: Column(
        children: [
          FaIcon(icon, size: 36),
          SizedBox(height: 8),
          Text(role,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_nameController, 'Name', FontAwesomeIcons.user),
                SizedBox(height: 16),
                _buildTextField(
                    _emailController, 'Email', FontAwesomeIcons.envelope),
                SizedBox(height: 16),
                _buildTextField(
                    _phoneController, 'Phone Number', FontAwesomeIcons.phone),
                SizedBox(height: 16),
                _buildPasswordField(_passwordController, 'Password',
                    FontAwesomeIcons.lock, _isPasswordVisible, () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                }),
                SizedBox(height: 16),
                _buildPasswordField(
                    _confirmPasswordController,
                    'Confirm Password',
                    FontAwesomeIcons.lock,
                    _isConfirmPasswordVisible, () {
                  setState(() =>
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                }),
                SizedBox(height: 16),
                if (_selectedRole == 'Student') ...[
                  _buildDropdownField(
                    value: _selectedClassTeacher,
                    label: 'Class Teacher',
                    icon: FontAwesomeIcons.chalkboardUser,
                    items: _classTeachers,
                    onChanged: (value) =>
                        setState(() => _selectedClassTeacher = value),
                  ),
                  SizedBox(height: 16),
                  _buildDropdownField(
                    value: _selectedCourse,
                    label: 'Course',
                    icon: FontAwesomeIcons.graduationCap,
                    items: _courses,
                    itemIcons: _courseIcons,
                    onChanged: (value) =>
                        setState(() => _selectedCourse = value),
                  ),
                ],
                if (_selectedRole == 'Teacher')
                  _buildTextField(_departmentController, 'Department',
                      FontAwesomeIcons.building),
                SizedBox(height: 24),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 12),
          child: FaIcon(icon, color: Colors.white, size: 20),
        ),
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Email' && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        if (label == 'Phone Number' && value.length != 10) {
          return 'Phone number must be 10 digits';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      IconData icon, bool isVisible, VoidCallback toggleVisibility) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 12),
          child: FaIcon(icon, color: Colors.white, size: 20),
        ),
        suffixIcon: IconButton(
          icon: FaIcon(
            isVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
            color: Colors.white,
            size: 20,
          ),
          onPressed: toggleVisibility,
        ),
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (value.length < 6) {
          return '$label must be at least 6 characters long';
        }
        if (label == 'Confirm Password' && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    Map<String, IconData>? itemIcons,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 12),
          child: FaIcon(icon, color: Colors.white, size: 20),
        ),
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      style: TextStyle(color: Colors.white),
      dropdownColor: Colors.blue.shade800,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Row(
            children: [
              if (itemIcons != null)
                FaIcon(itemIcons[item] ?? FontAwesomeIcons.question,
                    size: 16, color: Colors.white),
              if (itemIcons != null) SizedBox(width: 10),
              Text(item, style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a $label';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitRegistration,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue.shade600,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: _isSubmitting
          ? CircularProgressIndicator(color: Colors.white)
          : Text('Register',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
