import 'package:flutter/material.dart';
import '../../../../core/constants/app_roles.dart';

class RoleSelector extends StatelessWidget {
  final String? selectedRole;
  final void Function(String?) onRoleSelected;

  const RoleSelector({
    super.key,
    this.selectedRole, // ✅ pas "required"
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type de compte', style: TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<String>(
          title: const Text('Particulier'),
          value: AppRoles.owner,
          groupValue: selectedRole,
          onChanged: onRoleSelected,
        ),
        RadioListTile<String>(
          title: const Text('Société (Admin)'),
          value: AppRoles.companyAdmin,
          groupValue: selectedRole,
          onChanged: onRoleSelected,
        ),
        RadioListTile<String>(
          title: const Text('Professionnel (Garage)'),
          value: AppRoles.professional,
          groupValue: selectedRole,
          onChanged: onRoleSelected,
        ),
      ],
    );
  }
}