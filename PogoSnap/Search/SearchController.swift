////
////  SearchController.swift
////  PogoSnap
////
////  Created by Brandon Nguyen on 1/8/21.
////
//
//import UIKit
//
//class SearchController: UIViewController {
//
//    let searchDescriptions = [
//        "r/PokemonGo posts with ",
//        "r/PokemonGoSnap posts with ",
//        "Go to User "
//    ]
//
//    var searchText: String = "" {
//        didSet {
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//            }
//        }
//    }
//
//    let cellId = "cellId"
//    var previousText = ""
//    var searchController = UISearchController(searchResultsController: nil)
//    let tableView = UITableView()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        if traitCollection.userInterfaceStyle == .light {
//            tableView.backgroundColor = .white
//            view.backgroundColor = .white
//        } else {
//            tableView.backgroundColor = RedditConsts.redditDarkMode
//            view.backgroundColor = RedditConsts.redditDarkMode
//        }
//
//        searchController.searchBar.delegate = self
//        searchController.hidesNavigationBarDuringPresentation = false
//        searchController.obscuresBackgroundDuringPresentation = false
//        navigationItem.searchController = searchController
//        navigationItem.hidesSearchBarWhenScrolling = false
//
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.register(SearchTableCell.self, forCellReuseIdentifier: cellId)
//        tableView.rowHeight = 50
//        tableView.tableFooterView = UIView()
//
//        view.addSubview(tableView)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
//        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
//        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
//        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//    }
//
//}
//
//extension SearchController: UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 3
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SearchTableCell else {
//            return UITableViewCell()
//        }
//
//        cell.searchText = searchDescriptions[indexPath.row] + "\"\(searchText)\""
//        cell.index = indexPath.row
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if searchText.isEmpty {
//            DispatchQueue.main.async {
//                showErrorToast(controller: self, message: "Search is empty", seconds: 3.0)
//            }
//        } else {
//            if indexPath.row < 2 {
//                let searchPostsController = SearchPostsController()
//                searchPostsController.searchText = searchText
//                if indexPath.row == 0 {
//                    searchPostsController.subReddit = RedditConsts.pokemonGoSubredditName
//                } else {
//                    searchPostsController.subReddit = RedditConsts.subredditName
//                }
//                navigationController?.pushViewController(searchPostsController, animated: true)
//            } else {
//                let userProfileController = UserProfileController()
//                userProfileController.usernameProp = searchText
//                navigationController?.pushViewController(userProfileController, animated: true)
//            }
//        }
//    }
//
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        if searchText.isEmpty {
//            DispatchQueue.main.async {
//                showErrorToast(controller: self, message: "Search is empty", seconds: 3.0)
//            }
//        } else {
//            let searchPostsController = SearchPostsController()
//            searchPostsController.searchText = searchText
//            navigationController?.pushViewController(searchPostsController, animated: true)
//        }
//    }
//
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        self.searchText = ""
//    }
//
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        self.searchText = searchText
//    }
//}
