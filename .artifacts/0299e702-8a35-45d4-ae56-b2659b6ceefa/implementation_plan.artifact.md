# Plan de restructuration de GluMate - Étape 7 : Finalisation & Navigation

Ce plan détaille l'extraction du routeur principal (`GluMateRoot`) et la réduction de `lib/main.dart` à son rôle d'entrée minimal.

## User Review Required

> [!IMPORTANT]
> Cette étape est la dernière de la restructuration. Elle centralise toute la logique de navigation dans un seul fichier, rendant `main.dart` extrêmement concis.
> Une attention particulière sera portée aux imports pour éviter toute référence circulaire.

## Proposed Changes

### Navigation & Racine de l'App

#### [NEW] [glumate_root.dart](file:///C:/dev.mobile/Flutter_revisinnnn/Glumate_mobile/lib/navigation/glumate_root.dart)
- Contient `GluMateApp` (MaterialApp).
- Contient `GluMateRoot` et son état `_GluMateRootState` (le routeur).
- Gère le switch sur `AppScreen` et coordonne tous les écrans extraits aux étapes précédentes.
- Imports nécessaires :
    - Tous les écrans de `lib/screens/...`
    - `package:glumate_mobile/core/constants/app_screen.dart`
    - `package:glumate_mobile/core/theme/app_colors.dart`
    - `package:glumate_mobile/widgets/glumate_bottom_nav.dart`
    - Services utilisés : `AuthService`, `ChatService`, `DashboardService`.

---

### [MODIFY] [main.dart](file:///C:/dev.mobile/Flutter_revisinnnn/Glumate_mobile/lib/main.dart)
- Suppression de `GluMateApp` et `GluMateRoot`.
- Conservation de :
    - `main()` et initialisation des services/Firebase.
    - `MultiProvider` configuré.
    - Handlers de notifications en arrière-plan.
- Nettoyage des imports inutilisés (écrans, widgets génériques) qui seront désormais gérés par `glumate_root.dart`.
- Seul `GluMateApp` sera importé depuis `lib/navigation/glumate_root.dart`.

## Verification Plan

### Automated Tests
- `flutter clean` suivi de `flutter pub get` pour réinitialiser l'environnement.
- `flutter analyze` pour valider la structure finale.

### Manual Verification
- Lancer l'application (`flutter run`).
- Vérifier le cycle complet :
    - Login (Patient & Proche).
    - Navigation via la Bottom Nav (Home, Vision, Conseils, Profil).
    - Accès aux sous-écrans (Glycémie, Repas, Rapport, Hydratation, Ajout proche).
    - Test de déconnexion.
