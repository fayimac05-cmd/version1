const WRITE_ROLES = {
  administration: ['admin', 'professeur'],
  admin_filiere: ['admin', 'professeur', 'delegue', 'delegue_adjoint'],
  bde: ['admin', 'bde_president', 'bde_adjoint', 'bde'],
  groupe_filiere: ['etudiant', 'delegue', 'delegue_adjoint', 'admin'],
};

function sameFiliere(user, canal) {
  if (!canal.filiere) return true;
  const userFiliere = user.filiere || user.filiere_id;
  return String(userFiliere) === String(canal.filiere);
}

function canReadCanal(user, canal) {
  if (!user) return canal.type === 'administration' || canal.type === 'bde';

  if (['admin', 'professeur'].includes(user.role)) return true;

  switch (canal.type) {
    case 'administration':
    case 'bde':
      return true;
    case 'admin_filiere':
    case 'groupe_filiere':
      return sameFiliere(user, canal);
    default:
      return false;
  }
}

function canWriteCanal(user, canal) {
  if (!user || !canal) return false;

  if (canal.lecture_seule && !['admin', 'professeur'].includes(user.role)) {
    return false;
  }

  switch (canal.type) {
    case 'administration':
      return ['admin', 'professeur'].includes(user.role);

    case 'admin_filiere':
      if (['admin', 'professeur'].includes(user.role)) return true;
      return (
        ['delegue', 'delegue_adjoint'].includes(user.role) &&
        sameFiliere(user, canal)
      );

    case 'bde':
      return ['admin', 'bde_president', 'bde_adjoint', 'bde'].includes(user.role);

    case 'groupe_filiere':
      return sameFiliere(user, canal) && WRITE_ROLES.groupe_filiere.includes(user.role);

    default:
      return false;
  }
}

function canAccessConversation(user, conversation) {
  if (!user || !conversation) return false;
  if (['admin', 'professeur'].includes(user.role)) return true;
  return conversation.etudiant_id === user.id;
}

function canWriteConversation(user, conversation) {
  if (!canAccessConversation(user, conversation)) return false;
  if (['admin', 'professeur'].includes(user.role)) return true;
  return conversation.etudiant_id === user.id && user.role === 'etudiant';
}

module.exports = {
  canReadCanal,
  canWriteCanal,
  canAccessConversation,
  canWriteConversation,
};
