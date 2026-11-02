import '../../core/constants/app_constants.dart';
import '../../core/utils/crypto_helper.dart';
import '../../data/models/audit_models.dart';

/// Simulation d'authentification RBAC. Dans une version connectée à une
/// API, ce service appellerait un endpoint d'auth (OAuth2/OIDC) ; ici il
/// simule trois sessions utilisateur prédéfinies pour la démo PoC.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  Utilisateur? _utilisateurCourant;
  Utilisateur? get utilisateurCourant => _utilisateurCourant;

  static final List<Utilisateur> comptesDemo = [
    Utilisateur(id: 'usr-titulaire', nomAffiche: 'Titulaire (démo)', role: RoleUtilisateur.titulaire),
    Utilisateur(id: 'usr-preparateur', nomAffiche: 'Préparateur (démo)', role: RoleUtilisateur.preparateur),
    Utilisateur(id: 'usr-stagiaire', nomAffiche: 'Stagiaire (démo)', role: RoleUtilisateur.stagiaire),
  ];

  void connecter(Utilisateur utilisateur) {
    _utilisateurCourant = utilisateur;
  }

  void deconnecter() {
    _utilisateurCourant = null;
  }

  /// Hash SHA-256 d'un identifiant — aucune donnée de connexion en clair
  /// n'est jamais persistée en base.
  String hash(String identifiant) {
    return CryptoHelper.instance.hashIdentifiant(identifiant);
  }

  bool get estConnecte => _utilisateurCourant != null;
}
