import 'package:flutter/material.dart';
import '../../models/user_account.dart';
import '../../services/auth_service.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  
  SalaryType _salaryType = SalaryType.monthly;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authService = AuthService();
      final member = UserAccount(
        uid: '', 
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: UserRole.member,
        employeeId: _employeeIdController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        salaryType: _salaryType,
        baseSalary: double.parse(_salaryController.text.trim()),
        workingDays: [1, 2, 3, 4, 5, 6], 
        isFirstLogin: true, // New members must change password too
      );

      final result = await authService.registerMember(member, _passwordController.text.trim());
      
      setState(() => _isLoading = false);

      if (result != null && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('New member registered successfully!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to register member. Email might be in use.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Add New Member', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Employee Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Fill in the details to create a new member account', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(child: _buildField('Full Name', _nameController, Icons.person_outline)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Employee ID', _employeeIdController, Icons.badge_outlined)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  _buildField('Email Address', _emailController, Icons.email_outlined, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  
                  _buildField('Initial Password', _passwordController, Icons.lock_outline, obscure: true),
                  const SizedBox(height: 20),
                  
                  _buildField('Phone Number', _phoneController, Icons.phone_outlined, keyboard: TextInputType.phone),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<SalaryType>(
                          value: _salaryType,
                          decoration: _inputDecoration('Salary Type', Icons.payments_outlined),
                          items: SalaryType.values.map((type) {
                            return DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()));
                          }).toList(),
                          onChanged: (value) => setState(() => _salaryType = value!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Base Salary', _salaryController, Icons.account_balance_wallet_outlined, keyboard: TextInputType.number)),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Register Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboard, bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: _inputDecoration(label, icon),
      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey),
      filled: true,
      fillColor: Colors.blueGrey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      floatingLabelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
    );
  }
}
