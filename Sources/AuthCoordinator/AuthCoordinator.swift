import Foundation
import Socialite
import ABKeychain
import Combine

public class AuthCoordinator<Viewer: AccessTokenable>: ObservableObject {
    
    @Published public var authState: AuthState<Viewer> = .unauthorized
    
    @Published public var accessToken: String?
    
    @Published public var currentSocialite: (any Socialite)?

    private let accessTokenKeychain: ABKeychain!
    private var cancellables = Set<AnyCancellable>()
    private var socialites : [any Socialite] = []
    
    public init() {
        assert(Bundle.main.bundleIdentifier != nil)
        self.accessTokenKeychain = ABKeychain(
            service: Bundle.main.bundleIdentifier!,
            account: "accessToken"
        )
        
        if let accessToken = try? self.accessTokenKeychain.readItem() {
            self.accessToken = accessToken
        }
    }
    public func addSocialite(socialite: some Socialite) {
        self.socialites.append(socialite)
        
        socialite.statePublisher
            .receive(on: RunLoop.main)
            .sink { [unowned self] state in
            switch state {
            case .initialize:
                self.authState = .initialize
            case .loading:
                self.authState = .loading
            case .unauthorized:
                self.authState = .unauthorized
            case .authorized(let success):
                if let accessToken = success.accessToken {
                   try? self.accessTokenKeychain.saveItem(accessToken)
                } else {
                   try? self.accessTokenKeychain.deleteItem()
                }
                self.accessToken = success.accessToken
            case .error(let error):
                self.authState = .error(error)
            }
        }.store(in: &self.cancellables)
    }
    
    public func activeSocialite(socialiteType: any Socialite.Type) {
        self.currentSocialite = self.socialites.first { socialiteType == type(of: $0) }
    }
    
    public func authorize() {
        self.currentSocialite?.authorize()
    }
    
    public func unauthorize() {
        self.authState = .unauthorized
        try? self.accessTokenKeychain.deleteItem()
        self.accessToken = nil
        self.currentSocialite?.unauthorize()
    }
}
