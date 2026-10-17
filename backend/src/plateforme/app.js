(function () {
  'use strict';
  var API = '/api/plateforme';
  var cle = '';
  try { cle = sessionStorage.getItem('plateforme_cle') || ''; } catch (e) {}

  var $ = function (id) { return document.getElementById(id); };
  function msg(texte, ok) {
    var m = $('msg');
    m.textContent = texte || '';
    m.className = texte ? (ok ? 'ok' : 'err') : '';
  }
  function echapper(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function appel(methode, chemin, corps) {
    return fetch(API + chemin, {
      method: methode,
      headers: { 'Content-Type': 'application/json', 'x-platform-key': cle },
      body: corps ? JSON.stringify(corps) : undefined
    }).then(function (r) {
      return r.json().catch(function () { return {}; }).then(function (j) { j._status = r.status; return j; });
    });
  }

  function afficherListe(lignes) {
    var tb = $('liste');
    if (!lignes.length) { tb.innerHTML = '<tr><td colspan="6" class="mu">Aucun établissement.</td></tr>'; return; }
    tb.innerHTML = lignes.map(function (e) {
      return '<tr>' +
        '<td><strong>' + echapper(e.nom) + '</strong><div class="mu">' + echapper(e.sigle) + ' · ' + echapper(e.ville) + '</div></td>' +
        '<td><code>' + echapper(e.code) + '</code></td>' +
        '<td class="mu">' + echapper(e.modele_matricule || '—') + '</td>' +
        '<td class="mu">' + e.nb_etudiants + ' étudiants<br>' + e.nb_professeurs + ' prof. · ' + e.nb_admins + ' admin(s)</td>' +
        '<td><span class="pill ' + (e.actif ? 'on' : 'off') + '">' + (e.actif ? 'Actif' : 'Suspendu') + '</span></td>' +
        '<td><button class="sec" data-id="' + e.id + '" data-actif="' + (e.actif ? '1' : '0') + '">' + (e.actif ? 'Suspendre' : 'Réactiver') + '</button></td>' +
        '</tr>';
    }).join('');
  }

  function charger() {
    return appel('GET', '/etablissements').then(function (j) {
      if (j._status === 401 || j._status === 503 || j._status === 429) {
        $('contenu').className = 'hidden';
        $('connexion').className = 'card';
        msg(j.message || 'Accès refusé.', false);
        return false;
      }
      if (!j.success) { msg(j.message || 'Erreur.', false); return false; }
      $('connexion').className = 'card hidden';
      $('contenu').className = '';
      afficherListe(j.data);
      return true;
    });
  }

  $('btnConnexion').addEventListener('click', function () {
    cle = $('cle').value.trim();
    if (!cle) return;
    msg('');
    charger().then(function (ok) {
      if (ok) { try { sessionStorage.setItem('plateforme_cle', cle); } catch (e) {} }
    });
  });

  $('liste').addEventListener('click', function (ev) {
    var b = ev.target.closest('button[data-id]');
    if (!b) return;
    var actif = b.getAttribute('data-actif') === '1';
    var txt = actif
      ? 'Suspendre cet établissement ? Plus personne ne pourra se connecter ni saisir son code.'
      : 'Réactiver cet établissement ?';
    if (!window.confirm(txt)) return;
    appel('PATCH', '/etablissements/' + b.getAttribute('data-id'), { actif: !actif }).then(function (j) {
      msg(j.success ? 'Mis à jour.' : (j.message || 'Erreur.'), !!j.success);
      charger();
    });
  });

  $('formEtab').addEventListener('submit', function (ev) {
    ev.preventDefault();
    var f = ev.target;
    var v = function (n) { return f.elements[n].value.trim(); };
    var btn = $('btnCreer');
    btn.disabled = true;
    msg('');
    appel('POST', '/etablissements', {
      nom: v('nom'), sigle: v('sigle'), ville: v('ville'), campus: v('campus'), type: v('type'),
      code: v('code'), modele_matricule: v('modele_matricule'),
      admin: { nom: v('a_nom'), prenoms: v('a_prenoms'), email: v('a_email'), tel: v('a_tel'), motDePasse: f.elements.a_mdp.value }
    }).then(function (j) {
      btn.disabled = false;
      if (j.success) {
        var d = j.data;
        msg('Établissement créé. Code d\'accès : ' + d.etablissement.code + ' — Super Admin : ' + d.super_admin.email +
            ' (matricule ' + d.super_admin.matricule + '). Communiquez-lui le code et son mot de passe.', true);
        f.reset();
        charger();
      } else {
        msg(j.message || 'Erreur.', false);
      }
    }).catch(function () { btn.disabled = false; msg('Serveur injoignable.', false); });
  });

  if (cle) charger();
})();
