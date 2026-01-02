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
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values[map['role'] ?? 1],
      employeeId: map['employeeId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      salaryType: SalaryType.values[map['salaryType'] ?? 0],
      baseSalary: (map['baseSalary'] ?? 0).toDouble(),
      workingDays: List<int>.from(map['workingDays'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }
}
