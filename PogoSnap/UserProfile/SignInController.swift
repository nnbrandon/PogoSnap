//
//  SignInController.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/25/20.
//

import UIKit
import OAuthSwift
import SafariServices

class SignInController: OAuthViewController {
    
    var oauthSwift: OAuthSwift?
    
    let signInButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("   Sign in with Reddit", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.setImage(UIImage(named: "reddit-30")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(signIn), for: .touchDown)
        return btn
    }()
    
    let signUpButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Create a Reddit account", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.addTarget(self, action: #selector(signUp), for: .touchDown)
        return btn
    }()

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
        if traitCollection.userInterfaceStyle == .light {
            signInButton.setTitleColor(.black, for: .normal)
        } else {
            signInButton.setTitleColor(.white, for: .normal)
        }
        
        view.addSubview(signUpButton)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signUpButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 16).isActive = true
        if traitCollection.userInterfaceStyle == .light {
            signUpButton.setTitleColor(.black, for: .normal)
        } else {
            signUpButton.setTitleColor(.white, for: .normal)
        }
    }
    
    @objc private func signIn() {
        doAuthService()
    }
    
    @objc private func signUp() {
        let alert = UIAlertController(title: "You will be redirected to the sign up page.", message: "Once you are finished, please press the done button and sign in again.", preferredStyle: .alert)
        alert.view.layer.cornerRadius = 15
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let url = URL(string: "https://www.reddit.com/register/") else {return}
            let signupView = SFSafariViewController(url: url)
            self.present(signupView, animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func doAuthService() {
        let oauthSwift = OAuth2Swift(
            consumerKey:    RedditClient.Const.redditClientId,
            consumerSecret: RedditClient.Const.redditClientSecret,
            authorizeUrl:   RedditClient.Const.redditAuthorizeUrl,
            accessTokenUrl: RedditClient.Const.redditAccessTokenUrl,
            responseType:   RedditClient.Const.responseType
        )
        
        oauthSwift.accessTokenBasicAuthentification = true
        self.oauthSwift = oauthSwift
        oauthSwift.authorizeURLHandler = getURLHandler()
        let _ = oauthSwift.authorize(
            withCallbackURL: URL(string: RedditClient.Const.redditCallbackURL)!,
            scope: RedditClient.Const.scope,
            state: generateState(withLength: 20),
            parameters: ["duration": RedditClient.Const.duration]) { result in
                switch result {
                case .success(let (credential, _, _)):
                    print("accessToken = \(credential.oauthToken)")
                    print("refreshToken = \(credential.oauthRefreshToken)")
                    if let expireDate = credential.oauthTokenExpiresAt {
                        RedditClient.sharedInstance.registerCredentials(accessToken: credential.oauthToken, refreshToken: credential.oauthRefreshToken, expireDate: expireDate)
                        self.internalWebViewController.dismissWebViewController()
                    }
                case .failure(let error):
                    print(error.description)
                }
        }
    }
    
    func getURLHandler() -> OAuthSwiftURLHandlerType {
        internalWebViewController = WebViewController()
        internalWebViewController.view = UIView(frame: UIScreen.main.bounds) // needed if no nib or not loaded from storyboard
        internalWebViewController.delegate = self
        internalWebViewController.viewDidLoad() // allow WebViewController to use this ViewController as parent to be presented
        internalWebViewController.hidesBottomBarWhenPushed = true

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
