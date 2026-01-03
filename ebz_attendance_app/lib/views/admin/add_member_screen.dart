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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('REGISTRATION HUB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(60),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.person_add_rounded, color: Colors.black, size: 28),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personnel Intake', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          Text('Onboard new personnel to the operational network.', style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  
                  Row(
                    children: [
                      Expanded(child: _buildField('FULL LEGAL NAME', _nameController, Icons.person_outline_rounded)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildField('PERSONNEL ID', _employeeIdController, Icons.badge_outlined)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  _buildField('COMMUNICATION EMAIL', _emailController, Icons.alternate_email_rounded, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 32),
                  
                  _buildField('SECURE ACCESS TOKEN (PASSPHRASE)', _passwordController, Icons.key_rounded, obscure: true),
                  const SizedBox(height: 32),
                  
                  _buildField('CONTACT DIGITS', _phoneController, Icons.phone_iphone_rounded, keyboard: TextInputType.phone),
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('COMPENSATION MODEL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5, color: Colors.black26)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<SalaryType>(
                              value: _salaryType,
                              decoration: _inputDecoration('', Icons.payments_outlined),
                              items: SalaryType.values.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)));
                              }).toList(),
                              onChanged: (value) => setState(() => _salaryType = value!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: _buildField('BASE COMPENSATION', _salaryController, Icons.account_balance_rounded, keyboard: TextInputType.number)),
                    ],
                  ),
                  
                  const SizedBox(height: 60),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMember,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('AUTHORIZE REGISTRATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5, color: Colors.black26)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: _inputDecoration('', icon),
          validator: (value) => (value == null || value.isEmpty) ? 'REQUIRED' : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: Colors.black),
      filled: true,
      fillColor: Colors.black.withOpacity(0.03),
      contentPadding: const EdgeInsets.all(24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
