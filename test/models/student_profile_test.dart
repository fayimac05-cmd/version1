import 'package:flutter_test/flutter_test.dart';
import 'package:scolarhub/models/student_profile.dart';

void main() {
  late StudentProfile defaultStudent;
  late StudentProfile delegue;
  late StudentProfile delegueAdjoint;
  late StudentProfile bdePresident;
  late StudentProfile bdeAdjoint;
  late StudentProfile bdeMembre;
  late StudentProfile admin;
  late StudentProfile professeur;
  late StudentProfile parent;

  setUp(() {
    defaultStudent = const StudentProfile(
      nom: 'Ouedraogo',
      prenoms: 'Issa',
      matricule: 'MAT001',
      email: 'issa@ist.bf',
      telephone: '70000001',
      filiere: 'Informatique',
      motDePasse: 'pass123',
    );

    delegue = const StudentProfile(
      nom: 'Traore',
      prenoms: 'Fatou',
      matricule: 'MAT002',
      email: 'fatou@ist.bf',
      telephone: '70000002',
      filiere: 'Informatique',
      motDePasse: 'pass123',
      role: 'delegue',
      filiereRole: 'Informatique',
    );

    delegueAdjoint = const StudentProfile(
      nom: 'Diallo',
      prenoms: 'Amadou',
      matricule: 'MAT003',
      email: 'amadou@ist.bf',
      telephone: '70000003',
      filiere: 'Informatique',
      motDePasse: 'pass123',
      role: 'delegue_adjoint',
      filiereRole: 'Informatique',
    );

    bdePresident = const StudentProfile(
      nom: 'Kone',
      prenoms: 'Mariam',
      matricule: 'MAT004',
      email: 'mariam@ist.bf',
      telephone: '70000004',
      filiere: 'Gestion',
      motDePasse: 'pass123',
      role: 'bde_president',
    );

    bdeAdjoint = const StudentProfile(
      nom: 'Sawadogo',
      prenoms: 'Paul',
      matricule: 'MAT005',
      email: 'paul@ist.bf',
      telephone: '70000005',
      filiere: 'Gestion',
      motDePasse: 'pass123',
      role: 'bde_adjoint',
    );

    bdeMembre = const StudentProfile(
      nom: 'Zongo',
      prenoms: 'Ali',
      matricule: 'MAT006',
      email: 'ali@ist.bf',
      telephone: '70000006',
      filiere: 'Droit',
      motDePasse: 'pass123',
      role: 'bde_membre',
    );

    admin = const StudentProfile(
      nom: 'Admin',
      prenoms: 'Super',
      matricule: 'ADM001',
      email: 'admin@ist.bf',
      telephone: '70000007',
      filiere: 'Admin',
      motDePasse: 'admin123',
      role: 'admin',
    );

    professeur = const StudentProfile(
      nom: 'Prof',
      prenoms: 'Jean',
      matricule: 'PRO001',
      email: 'prof@ist.bf',
      telephone: '70000008',
      filiere: 'Informatique',
      motDePasse: 'prof123',
      role: 'professeur',
    );

    parent = const StudentProfile(
      nom: 'Parent',
      prenoms: 'Marie',
      matricule: 'PAR001',
      email: 'parent@ist.bf',
      telephone: '70000009',
      filiere: '',
      motDePasse: 'parent123',
      role: 'parent',
    );
  });

  group('StudentProfile construction', () {
    test('creates with required fields and defaults', () {
      expect(defaultStudent.nom, 'Ouedraogo');
      expect(defaultStudent.prenoms, 'Issa');
      expect(defaultStudent.matricule, 'MAT001');
      expect(defaultStudent.email, 'issa@ist.bf');
      expect(defaultStudent.telephone, '70000001');
      expect(defaultStudent.filiere, 'Informatique');
      expect(defaultStudent.motDePasse, 'pass123');
      expect(defaultStudent.domaine, '');
      expect(defaultStudent.niveau, '');
      expect(defaultStudent.role, 'etudiant');
      expect(defaultStudent.filiereRole, isNull);
    });

    test('creates with all optional fields', () {
      const student = StudentProfile(
        nom: 'Test',
        prenoms: 'User',
        matricule: 'T001',
        email: 'test@ist.bf',
        telephone: '70000000',
        filiere: 'Info',
        motDePasse: 'pwd',
        domaine: 'Sciences',
        niveau: 'L3',
        role: 'delegue',
        filiereRole: 'Info',
      );
      expect(student.domaine, 'Sciences');
      expect(student.niveau, 'L3');
      expect(student.role, 'delegue');
      expect(student.filiereRole, 'Info');
    });
  });

  group('estDelegue', () {
    test('returns true for delegue role', () {
      expect(delegue.estDelegue, isTrue);
    });

    test('returns true for delegue_adjoint role', () {
      expect(delegueAdjoint.estDelegue, isTrue);
    });

    test('returns false for regular student', () {
      expect(defaultStudent.estDelegue, isFalse);
    });

    test('returns false for bde_president', () {
      expect(bdePresident.estDelegue, isFalse);
    });

    test('returns false for admin', () {
      expect(admin.estDelegue, isFalse);
    });
  });

  group('peutEcrireCanal', () {
    test('delegue can write to their filiere canal', () {
      expect(delegue.peutEcrireCanal('Informatique'), isTrue);
    });

    test('delegue with matching filiereRole/filiere can write to any canal', () {
      // When filiereRole == filiere, the condition (filiereRole == filiere) is always true
      expect(delegue.peutEcrireCanal('Gestion'), isTrue);
    });

    test('delegue with mismatched filiereRole cannot write to unrelated canal', () {
      // Create a delegue whose filiereRole differs from their filiere
      const mismatchedDelegue = StudentProfile(
        nom: 'Test',
        prenoms: 'Delegue',
        matricule: 'MAT099',
        email: 'test@ist.bf',
        telephone: '70000099',
        filiere: 'Gestion',
        motDePasse: 'pass',
        role: 'delegue',
        filiereRole: 'Droit',
      );
      // filiereRole('Droit') != 'Informatique' AND filiereRole('Droit') != filiere('Gestion')
      expect(mismatchedDelegue.peutEcrireCanal('Informatique'), isFalse);
    });

    test('delegue_adjoint can write to their filiere canal', () {
      expect(delegueAdjoint.peutEcrireCanal('Informatique'), isTrue);
    });

    test('regular student cannot write to canal', () {
      expect(defaultStudent.peutEcrireCanal('Informatique'), isFalse);
    });

    test('bde_president cannot write to filiere canal', () {
      expect(bdePresident.peutEcrireCanal('Gestion'), isFalse);
    });
  });

  group('peutPublierBDE', () {
    test('returns true for bde_president', () {
      expect(bdePresident.peutPublierBDE, isTrue);
    });

    test('returns true for bde_adjoint', () {
      expect(bdeAdjoint.peutPublierBDE, isTrue);
    });

    test('returns false for bde_membre', () {
      expect(bdeMembre.peutPublierBDE, isFalse);
    });

    test('returns false for regular student', () {
      expect(defaultStudent.peutPublierBDE, isFalse);
    });

    test('returns false for delegue', () {
      expect(delegue.peutPublierBDE, isFalse);
    });
  });

  group('estBDE', () {
    test('returns true for bde_president', () {
      expect(bdePresident.estBDE, isTrue);
    });

    test('returns true for bde_adjoint', () {
      expect(bdeAdjoint.estBDE, isTrue);
    });

    test('returns true for bde_membre', () {
      expect(bdeMembre.estBDE, isTrue);
    });

    test('returns false for regular student', () {
      expect(defaultStudent.estBDE, isFalse);
    });

    test('returns false for delegue', () {
      expect(delegue.estBDE, isFalse);
    });

    test('returns false for admin', () {
      expect(admin.estBDE, isFalse);
    });
  });

  group('roleLabel', () {
    test('returns correct label for delegue', () {
      expect(delegue.roleLabel, 'Délégué(e)');
    });

    test('returns correct label for delegue_adjoint', () {
      expect(delegueAdjoint.roleLabel, 'Adjoint(e) Délégué(e)');
    });

    test('returns correct label for bde_president', () {
      expect(bdePresident.roleLabel, 'Délégué(e) Général(e) BDE');
    });

    test('returns correct label for bde_adjoint', () {
      expect(bdeAdjoint.roleLabel, 'Adjoint(e) Délégué(e) Général(e) BDE');
    });

    test('returns correct label for bde_membre', () {
      expect(bdeMembre.roleLabel, 'Membre BDE');
    });

    test('returns correct label for admin', () {
      expect(admin.roleLabel, 'Administrateur');
    });

    test('returns correct label for professeur', () {
      expect(professeur.roleLabel, 'Professeur');
    });

    test('returns correct label for parent', () {
      expect(parent.roleLabel, 'Parent');
    });

    test('returns default label for etudiant', () {
      expect(defaultStudent.roleLabel, 'Étudiant(e)');
    });
  });

  group('roleBadgeEmoji', () {
    test('returns medal for delegue', () {
      expect(delegue.roleBadgeEmoji, '🎖️');
    });

    test('returns sports medal for delegue_adjoint', () {
      expect(delegueAdjoint.roleBadgeEmoji, '🏅');
    });

    test('returns crown for bde_president', () {
      expect(bdePresident.roleBadgeEmoji, '👑');
    });

    test('returns star for bde_adjoint', () {
      expect(bdeAdjoint.roleBadgeEmoji, '⭐');
    });

    test('returns party for bde_membre', () {
      expect(bdeMembre.roleBadgeEmoji, '🎉');
    });

    test('returns empty string for regular student', () {
      expect(defaultStudent.roleBadgeEmoji, '');
    });

    test('returns empty string for admin', () {
      expect(admin.roleBadgeEmoji, '');
    });

    test('returns empty string for professeur', () {
      expect(professeur.roleBadgeEmoji, '');
    });
  });

  group('copyWith', () {
    test('returns identical copy when no arguments provided', () {
      final copy = defaultStudent.copyWith();
      expect(copy.nom, defaultStudent.nom);
      expect(copy.prenoms, defaultStudent.prenoms);
      expect(copy.matricule, defaultStudent.matricule);
      expect(copy.email, defaultStudent.email);
      expect(copy.telephone, defaultStudent.telephone);
      expect(copy.filiere, defaultStudent.filiere);
      expect(copy.motDePasse, defaultStudent.motDePasse);
      expect(copy.domaine, defaultStudent.domaine);
      expect(copy.niveau, defaultStudent.niveau);
      expect(copy.role, defaultStudent.role);
      expect(copy.filiereRole, defaultStudent.filiereRole);
    });

    test('updates nom only', () {
      final copy = defaultStudent.copyWith(nom: 'Nouveau');
      expect(copy.nom, 'Nouveau');
      expect(copy.prenoms, defaultStudent.prenoms);
    });

    test('updates email only', () {
      final copy = defaultStudent.copyWith(email: 'new@ist.bf');
      expect(copy.email, 'new@ist.bf');
      expect(copy.nom, defaultStudent.nom);
    });

    test('updates role and filiereRole', () {
      final copy = defaultStudent.copyWith(
        role: 'delegue',
        filiereRole: 'Informatique',
      );
      expect(copy.role, 'delegue');
      expect(copy.filiereRole, 'Informatique');
      expect(copy.estDelegue, isTrue);
    });

    test('updates multiple fields simultaneously', () {
      final copy = defaultStudent.copyWith(
        nom: 'New',
        prenoms: 'Name',
        telephone: '99999999',
        niveau: 'M1',
      );
      expect(copy.nom, 'New');
      expect(copy.prenoms, 'Name');
      expect(copy.telephone, '99999999');
      expect(copy.niveau, 'M1');
      expect(copy.email, defaultStudent.email);
    });
  });
}
