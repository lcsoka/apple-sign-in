import Foundation
import Capacitor
import AuthenticationServices

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitor.ionicframework.com/docs/plugins/ios
 */
@objc(SignInWithApple)
public class SignInWithApple: CAPPlugin {
    var call: CAPPluginCall?

    @objc func authorize(_ call: CAPPluginCall) {
        self.call = call

        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = getRequestedScopes(from: call)
            request.state = call.getString("state")
            request.nonce = call.getString("nonce")

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests()
        } else {
            call.reject("Sign in with Apple is available on iOS 13.0+ only.")
        }
    }

    @available(iOS 13.0, *)
    func getRequestedScopes(from call: CAPPluginCall) -> [ASAuthorization.Scope]? {
        var requestedScopes: [ASAuthorization.Scope] = []

        if let scopesStr = call.getString("scopes") {
            if scopesStr.contains("name") {
                requestedScopes.append(.fullName)
            }

            if scopesStr.contains("email") {
                requestedScopes.append(.email)
            }
        }

        if requestedScopes.count > 0 {
            return requestedScopes
        }

        return nil
    }
}

@available(iOS 13.0, *)
extension SignInWithApple: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            call?.reject("Please, try again.")

            return
        }

        let result = [
            "response": [
                "user": appleIDCredential.user,
                "email": appleIDCredential.email,
                "givenName": appleIDCredential.fullName?.givenName,
                "familyName": appleIDCredential.fullName?.familyName,
                "identityToken": String(data: appleIDCredential.identityToken!, encoding: .utf8),
                "authorizationCode": String(data: appleIDCredential.authorizationCode!, encoding: .utf8)
            ]
        ]

        call?.resolve(result as PluginResultData)
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        call?.reject(error.localizedDescription)
    }
}
