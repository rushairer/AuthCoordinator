//
//  AppleAuthButton.swift
//  
//
//  Created by Abenx on 2023/1/2.
//

import SwiftUI
import Socialite
import AuthenticationServices

public struct AppleAuthButton<Viewer>: View where Viewer: AccessTokenable{
    
    public init(authCoordinator: AuthCoordinator<Viewer>?) {
        self.authCoordinator = authCoordinator
    }
    
    weak private var authCoordinator: AuthCoordinator<Viewer>?
    @Environment(\.colorScheme) var colorScheme
    
    public var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                self.authCoordinator?.activeSocialite(socialiteType: SocialiteApple.self)
                request.requestedScopes = [.email, .fullName]
            },
            onCompletion: { result in
                switch result {
                case .success (let result):                    
                    if let socialite = self.authCoordinator?.currentSocialite as? SocialiteApple {
                        socialite.auth = result
                    }
                    self.authCoordinator?.authorize()
                case .failure (let error):
                    print("SignIn Error: " + error.localizedDescription)
                }
            }
        )
        .signInWithAppleButtonStyle(self.colorScheme == .light ? .black : .white)
    }
}
