enum UserRole { admin, member }

enum SalaryType { monthly, daily, hourly }

class UserAccount {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String employeeId;
  final String phoneNumber;
  final SalaryType salaryType;
  final double baseSalary;
  final List<int> workingDays; // 1 = Monday, 7 = Sunday
  final bool isActive;
  final bool isFirstLogin;

  UserAccount({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.employeeId,
    required this.phoneNumber,
    required this.salaryType,
    required this.baseSalary,
    required this.workingDays,
    this.isActive = true,
    this.isFirstLogin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.index,
      'employeeId': employeeId,
      'phoneNumber': phoneNumber,
      'salaryType': salaryType.index,
      'baseSalary': baseSalary,
      'workingDays': workingDays,
      'isActive': isActive,
      'isFirstLogin': isFirstLogin,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    int getInt(dynamic value, int defaultValue) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is bool) return value ? 0 : 1; // Map true to 0 (Admin), false to 1 (Member) as a guess, but safer to stick to default
      return defaultValue;
    }

    int roleIndex = getInt(map['role'], 1);
    if (roleIndex < 0 || roleIndex >= UserRole.values.length) roleIndex = 1;

    int salaryIndex = getInt(map['salaryType'], 0);
    if (salaryIndex < 0 || salaryIndex >= SalaryType.values.length) salaryIndex = 0;

    return UserAccount(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values[roleIndex],
      employeeId: map['employeeId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      salaryType: SalaryType.values[salaryIndex],
      baseSalary: (map['baseSalary'] ?? 0).toDouble(),
      workingDays: List<int>.from(map['workingDays'] ?? []),
      isActive: map['isActive'] == true,
      isFirstLogin: map['isFirstLogin'] == true,
    );
  }
}
