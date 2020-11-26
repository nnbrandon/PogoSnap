//
//  SignInController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/25/20.
//

import UIKit
import OAuthSwift
import KeychainAccess

class SignInController: OAuthViewController {
    
    let keychain = Keychain(service: "com.PogoSnap")
    var oauthSwift: OAuthSwift?
    var currentParameters = [String: String]()
    
    let signInButton = UIButton(type: .system)

    lazy var internalWebViewController: WebViewController = {
        let controller = WebViewController()
        controller.view = UIView(frame: UIScreen.main.bounds) // needed if no nib or not loaded from storyboard
        controller.delegate = self
        controller.viewDidLoad() // allow WebViewController to use this ViewController as parent to be presented
        controller.hidesBottomBarWhenPushed = true
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(signInButton)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        signInButton.addTarget(self, action: #selector(signIn), for: .touchDown)
        signInButton.setTitle("Sign In", for: .normal)
    }
    
    @objc fileprivate func signIn() {
        doAuthService()
    }
    
    func doAuthService() {
        let oauthSwift = OAuth2Swift(
            consumerKey:    RedditClient.Const.clientId,
            consumerSecret: RedditClient.Const.clientSecret,
            authorizeUrl:   RedditClient.Const.authorizeUrl,
            accessTokenUrl: RedditClient.Const.accessTokenUrl,
            responseType:   RedditClient.Const.responseType
        )
        
        oauthSwift.accessTokenBasicAuthentification = true
        self.oauthSwift = oauthSwift
        oauthSwift.authorizeURLHandler = getURLHandler()
        let _ = oauthSwift.authorize(
            withCallbackURL: URL(string: RedditClient.Const.callbackURL)!,
            scope: RedditClient.Const.scope,
            state: generateState(withLength: 20),
            parameters: ["duration": RedditClient.Const.duration]) { result in
                switch result {
                case .success(let (credential, _, _)):
                    print("accessToken = \(credential.oauthToken)")
                    print("refreshToken = \(credential.oauthRefreshToken)")
                    self.keychain["accessToken"] = credential.oauthToken
                    self.keychain["refreshToken"] = credential.oauthRefreshToken
                case .failure(let error):
                    print(error.description)
                }
        }
    }
    
    func getURLHandler() -> OAuthSwiftURLHandlerType {
        if internalWebViewController.parent == nil {
            addChild(internalWebViewController)
        }
        return internalWebViewController
    }
}

extension SignInController: OAuthWebViewControllerDelegate {
    func oauthWebViewControllerDidPresent() {
    }
    
    func oauthWebViewControllerDidDismiss() {
    }
    
    func oauthWebViewControllerWillAppear() {
    }
    
    func oauthWebViewControllerDidAppear() {
    }
    
    func oauthWebViewControllerWillDisappear() {
    }
    
    func oauthWebViewControllerDidDisappear() {
        oauthSwift?.cancel()
    }
    
}
