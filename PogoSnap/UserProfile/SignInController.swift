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
    
    let redditOAuth = RedditOAuth()
    var compact: Bool = false

    let signInButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("   Sign in with Reddit", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.setImage(UIImage(named: "reddit-30")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(signIn), for: .touchDown)
        return btn
    }()
    
    lazy var signInAppleGoogle: UIButton = {
        let btn = UIButton()
        btn.setTitle("   Sign in with Apple/Google", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.setImage(UIImage(named: "apple-30")?.withRenderingMode(.alwaysTemplate), for: .normal)
        if traitCollection.userInterfaceStyle == .light {
            btn.tintColor = .black
        } else {
            btn.tintColor = .white
        }
        btn.addTarget(self, action: #selector(signInWithAppleGoogle), for: .touchDown)
        return btn
    }()
    
    let signUpButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Create a Reddit account", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.addTarget(self, action: #selector(signUp), for: .touchDown)
        return btn
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
        
        view.addSubview(signInAppleGoogle)
        signInAppleGoogle.translatesAutoresizingMaskIntoConstraints = false
        signInAppleGoogle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInAppleGoogle.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 16).isActive = true
        if traitCollection.userInterfaceStyle == .light {
            signInAppleGoogle.setTitleColor(.black, for: .normal)
        } else {
            signInAppleGoogle.setTitleColor(.white, for: .normal)
        }
        
        view.addSubview(signUpButton)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signUpButton.topAnchor.constraint(equalTo: signInAppleGoogle.bottomAnchor, constant: 16).isActive = true
        if traitCollection.userInterfaceStyle == .light {
            signUpButton.setTitleColor(.black, for: .normal)
        } else {
            signUpButton.setTitleColor(.white, for: .normal)
        }
    }
        
    @objc private func signIn() {
        compact = true
        redditOAuth.changeCompact(compact: true)
        doAuthService()
    }
    
    @objc private func signInWithAppleGoogle() {
        compact = false
        redditOAuth.changeCompact(compact: false)
        let alert = UIAlertController(title: "Sign in with Apple or Google", message: "Just a few couple of steps to sign in with these services! \n\nTap \"Start Sign In\" below then tap the button to sign in with Apple or Google. \n\nAfter signing in, tap the \"Done\" button in the top left of the browser.", preferredStyle: .alert)
        alert.view.layer.cornerRadius = 15
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: "Start Sign In", style: .default, handler: { _ in
            self.doAuthService()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func doAuthService() {
        redditOAuth.doAuth(urlHandlerType: getUrlHandler()) { result in
            switch result {
            case .success:
                break
            case .error:
                DispatchQueue.main.async {
                    showErrorToast(controller: self, message: "Unable to sign in", seconds: 2.0)
                }
            }
        }
    }
    
    private func getUrlHandler() -> OAuthSwiftURLHandlerType {
        let safari = SafariURLHandler(viewController: self, oauthSwift: redditOAuth.oauthSwift)
        safari.delegate = self
        return safari
    }
    
    private func signInCompleteForAppleGoogle() {
        let alert = UIAlertController(title: "Finished Signing in? Last Step!", message: "Tap \"Finish Sign In\" below and it'll redirect you to a page where you can enable your account for PogoSnap", preferredStyle: .alert)
        alert.view.layer.cornerRadius = 15
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: "Finish Sign In", style: .default, handler: { _ in
            self.compact = true
            self.redditOAuth.changeCompact(compact: true)
            self.doAuthService()
        }))
        present(alert, animated: true, completion: nil)
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
        redditOAuth.oauthSwift.cancel()
    }
    
}

extension SignInController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if !compact {
            signInCompleteForAppleGoogle()
        }
    }
}
