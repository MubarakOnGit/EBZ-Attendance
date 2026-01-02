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
        uid: '', // Will be set by Firebase Auth
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: UserRole.member,
        employeeId: _employeeIdController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        salaryType: _salaryType,
        baseSalary: double.parse(_salaryController.text.trim()),
        workingDays: [1, 2, 3, 4, 5, 6], // Default Mon-Sat
      );

      final result = await authService.registerMember(member, _passwordController.text.trim());
      
      setState(() => _isLoading = false);

      if (result != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add member.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(labelText: 'Employee ID', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? 'Enter ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Initial Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => (value == null || value.length < 6) ? 'Password min 6 chars' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SalaryType>(
                value: _salaryType,
                decoration: const InputDecoration(labelText: 'Salary Type', border: OutlineInputBorder()),
                items: SalaryType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()));
                }).toList(),
                onChanged: (value) => setState(() => _salaryType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(labelText: 'Base Salary', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter valid salary' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMember,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
