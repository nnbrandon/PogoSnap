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
    
    var compact: Bool = true
    var signUpState: Bool = false
    
    let pogoSnapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 50
        imageView.image = UIImage(named: "PogoSnap-icon")
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let signInLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign to access your Reddit account, like and dislike posts, comment, upload images, and more!"
        label.font = UIFont.systemFont(ofSize: 16, weight: .light)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    let signInButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("   Sign in with Reddit", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.setImage(UIImage(named: "reddit-30")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(signIn), for: .touchDown)
        return btn
    }()
    
    let signInAppleGoogle: UIButton = {
        let btn = UIButton()
        btn.setTitle(" Sign into Reddit with Apple/Google", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.setImage(UIImage(named: "apple-30")?.withRenderingMode(.alwaysTemplate), for: .normal)
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
        
        view.addSubview(signInLabel)
        signInLabel.translatesAutoresizingMaskIntoConstraints = false
        signInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50).isActive = true
        signInLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        signInLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
        
        view.addSubview(pogoSnapImageView)
        pogoSnapImageView.translatesAutoresizingMaskIntoConstraints = false
        pogoSnapImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pogoSnapImageView.bottomAnchor.constraint(equalTo: signInLabel.topAnchor, constant: -16).isActive = true
        pogoSnapImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        pogoSnapImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
        pogoSnapImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true

        view.addSubview(signInButton)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInButton.topAnchor.constraint(equalTo: signInLabel.bottomAnchor, constant: 50).isActive = true
        if traitCollection.userInterfaceStyle == .light {
            signInButton.setTitleColor(.black, for: .normal)
        } else {
            signInButton.setTitleColor(.white, for: .normal)
        }
        
        view.addSubview(signInAppleGoogle)
        signInAppleGoogle.translatesAutoresizingMaskIntoConstraints = false
        signInAppleGoogle.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signInAppleGoogle.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 32).isActive = true
        if traitCollection.userInterfaceStyle == .light {
            signInAppleGoogle.setTitleColor(.black, for: .normal)
            signInAppleGoogle.tintColor = .black
        } else {
            signInAppleGoogle.setTitleColor(.white, for: .normal)
            signInAppleGoogle.tintColor = .white
        }
        
        view.addSubview(signUpButton)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signUpButton.topAnchor.constraint(equalTo: signInAppleGoogle.bottomAnchor, constant: 32).isActive = true
        if traitCollection.userInterfaceStyle == .light {
            signUpButton.setTitleColor(.black, for: .normal)
        } else {
            signUpButton.setTitleColor(.white, for: .normal)
        }
    }
        
    @objc private func signIn() {
        generatorImpactOccured()
        if !compact {
            compact = true
            redditOAuth.changeCompact(compact: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.doAuthService()
        }
    }
    
    @objc private func signInWithAppleGoogle() {
        generatorImpactOccured()
        if compact {
            compact = false
            redditOAuth.changeCompact(compact: false)
        }

        let alert = UIAlertController(title: "Sign in with Apple or Google", message: "Just a few couple of steps to sign in with these services! \n\nTap \"Start Sign In\" below then tap the button to sign in with Apple or Google. \n\nAfter signing in, tap the \"Done\" button in the top left of the browser. \n\nIf you are already signed in on the next page, enable your account for PogoSnap.", preferredStyle: .alert)
        alert.view.layer.cornerRadius = 15
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Start Sign In", style: .default, handler: { _ in
            self.doAuthService()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func signUp() {
        generatorImpactOccured()
        
        let alert = UIAlertController(title: "You will be redirected to the sign up page.", message: "Once you are finished, press the done button on the top left corner.", preferredStyle: .alert)
        alert.view.layer.cornerRadius = 15
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.signUpState = true
            guard let url = URL(string: "https://www.reddit.com/register/") else {return}
            let signupView = SFSafariViewController(url: url)
            signupView.delegate = self
            self.present(signupView, animated: true, completion: nil)
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
    
    private func signUpCompletion() {
        if !compact {
            compact = true
            redditOAuth.changeCompact(compact: true)
        }
        let alert = UIAlertController(title: "Finished Signing up?", message: "Tap \"Sign In\" below and it will redirect you to a page where you can enable your account for PogoSnap", preferredStyle: .alert)
        alert.view.layer.cornerRadius = 15
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Sign In", style: .default, handler: { _ in
            self.doAuthService()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func signInCompleteForAppleGoogle() {
        if !compact {
            compact = true
            redditOAuth.changeCompact(compact: true)
        }
        let alert = UIAlertController(title: "Finished Signing in? Last Step!", message: "Tap \"Finish Sign In\" below and it will redirect you to a page where you can enable your account for PogoSnap", preferredStyle: .alert)
        alert.view.layer.cornerRadius = 15
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Finish Sign In", style: .default, handler: { _ in
            self.doAuthService()
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
        if signUpState {
            signUpState = false
            signUpCompletion()
        } else if !compact {
            signInCompleteForAppleGoogle()
        }
    }
}
