enum AdminRole {
  superAdmin,
  scolarite,
  examens,
  secretariat,
  communication,
  cycleDirecteur,
}

extension AdminRoleExtension on AdminRole {
  String get label {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Administrateur';
      case AdminRole.scolarite:
        return 'Resp. Scolarité & Pédagogie';
      case AdminRole.examens:
        return 'Resp. Examens & Notes';
      case AdminRole.secretariat:
        return 'Secrétariat & Inscriptions';
      case AdminRole.communication:
        return 'Chargé Communication & BDE';
      case AdminRole.cycleDirecteur:
        return 'Directeur de Cycle';
    }
  }

  String get code {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.scolarite:
        return 'scolarite';
      case AdminRole.examens:
        return 'examens';
      case AdminRole.secretariat:
        return 'secretariat';
      case AdminRole.communication:
        return 'communication';
      case AdminRole.cycleDirecteur:
        return 'cycle';
    }
  }

  static AdminRole fromCode(String? code) {
    switch (code?.toLowerCase().trim()) {
      case 'scolarite':
      case 'academic':
        return AdminRole.scolarite;
      case 'examens':
      case 'notes':
        return AdminRole.examens;
      case 'secretariat':
        return AdminRole.secretariat;
      case 'communication':
      case 'bde':
        return AdminRole.communication;
      case 'cycle':
      case 'directeur_cycle':
        return AdminRole.cycleDirecteur;
      case 'super_admin':
      case 'superadmin':
      default:
        return AdminRole.superAdmin;
    }
  }
}
