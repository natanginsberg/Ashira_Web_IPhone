import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignIn {
  Future<void> signIn() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final appleIdCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oAuthProvider = OAuthProvider('apple.com');
    final credential = oAuthProvider.credential(
      idToken: appleIdCredential.identityToken,
      accessToken: appleIdCredential.authorizationCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;
    var fullName = "";
    if (appleIdCredential.givenName != null)
      fullName += appleIdCredential.givenName! + " ";
    if (appleIdCredential.familyName != null)
      fullName += appleIdCredential.familyName!;
    if (fullName != "") {
      await firebaseUser.updateProfile(displayName: fullName);
    }
  }
}
