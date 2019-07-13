/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
import SoraDocuments

class DocumentsStorageBrokenFilesTests: DocumentsStorageBaseTests {
    let brokenConfiguration: DocumentsStorageConfigurationProtocol = {
        var config = DocumentsStorageConfiguration.defaultConfiguration()
        config.encryptionAlgoritm = BrokenEncryptionAlgorithm()
        config.excludeFromiCloudBackup = true
        return config
    }()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFirstBrokenSecondNormalWhenReadQuery() {
        // given
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullName")
        jsonNode.set(integer: 10, for: "votes")

        setupNew(configuration: brokenConfiguration)
        XCTAssertNotNil(saveDocumentNode(node: jsonNode))

        jsonNode.set(integer: 11, for: "votes")

        setupNew(configuration: configuration)
        XCTAssertNotNil(saveDocumentNode(node: jsonNode))

        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 2

        var firstQueryDocument: JSONDocumentNode!
        var secondQueryDocument: JSONDocumentNode!

        // when
        storage.queryAll().fetchAll(runCompletionIn: .main) { (documents, error) in
            XCTAssertEqual(documents?.count, 1)
            XCTAssertNil(error)

            firstQueryDocument = documents?.first?.rootNode as? JSONDocumentNode

            expectation.fulfill()
        }

        storage.queryAll().fetchFirst(runCompletionIn: .main) { (document, error) in
            XCTAssertNotNil(document)
            XCTAssertNil(error)

            secondQueryDocument = document?.rootNode as? JSONDocumentNode

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.defaultTimeout)

        // then
        if firstQueryDocument == nil {
            XCTFail()
            return
        }

        if secondQueryDocument == nil {
            XCTFail()
            return
        }

        XCTAssertEqual(jsonNode.string(for: "fullname"), firstQueryDocument.string(for: "fullname"))
        XCTAssertEqual(jsonNode.string(for: "fullname"), secondQueryDocument.string(for: "fullname"))
        XCTAssertEqual(jsonNode.integer(for: "votes"), firstQueryDocument.integer(for: "votes"))
        XCTAssertEqual(jsonNode.integer(for: "votes"), secondQueryDocument.integer(for: "votes"))
    }

}
