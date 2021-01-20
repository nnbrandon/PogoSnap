//
//  CommentsViewModelTest.swift
//  PogoSnapTests
//
//  Created by Brandon Nguyen on 1/17/21.
//

import XCTest
@testable import PogoSnap

class CommentsViewModelTest: XCTestCase {

    let post = Post(author: "test", title: "test", imageSources: [ImageSource](), score: 0, numComments: 0, commentsLink: "https:www.reddit.com/test/123", archived: false, id: "123", created_utc: 123, liked: nil, aspectFit: false, user_icon: nil, subReddit: "test")

    let mockService = MockRedditStaticService()

    func test_fetchComments() throws {
        let viewModel = CommentsViewModel(post: post, authenticated: false, redditStaticClient: mockService)
        let expectedFlattenedComments = viewModel.flattenComments(comments: mockService.getExpectedComments())
        viewModel.fetchComments { error in
            XCTAssertNil(error)
            var replyCount = 0
            let flattenedComments = viewModel.flattenedComments
            for comment in flattenedComments {
                if comment.author.contains("replyIndex") {
                    replyCount += 1
                }
            }
            XCTAssertEqual(replyCount, 4)
            XCTAssertEqual(flattenedComments.count, 8)
            XCTAssertEqual(flattenedComments, expectedFlattenedComments)
        }
    }
    
    func test_flattenComments() throws {
    }
}
