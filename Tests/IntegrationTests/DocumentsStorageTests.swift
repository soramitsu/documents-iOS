/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
import SoraDocuments

class DocumentsStorageTests: DocumentsStorageBaseTests {

    func testDocumentCreatedWithMatchingConfiguration() {
        // given
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullName")
        jsonNode.set(integer: 10, for: "votes")

        var createdDocumentName: String!

        let creationExpectation = XCTestExpectation()

        // when
        storage.create(jsonNode, runCompletionIn: .main) { (documentName, error) in
            if let existingDocumentName = documentName, error == nil {
                createdDocumentName = existingDocumentName
            } else {
                XCTFail()
            }

            creationExpectation.fulfill()
        }

        // then
        wait(for: [creationExpectation], timeout: Constants.defaultTimeout)

        let documentURL = userDirectoryURL.appendingPathComponent(createdDocumentName)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: documentURL.path, isDirectory: &isDirectory))
        XCTAssertTrue(!isDirectory.boolValue)

        let resources = try! userDirectoryURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertTrue(resources.isExcludedFromBackup == configuration.excludeFromiCloudBackup)
    }

    func testDocumentCreatedWithMatchingContent() {
        // given
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullName")
        jsonNode.set(integer: 10, for: "votes")

        var createdDocumentName: String!

        let creationExpectation = XCTestExpectation()

        // when
        storage.create(jsonNode, runCompletionIn: .main) { (documentName, error) in
            if let existingDocumentName = documentName, error == nil {
                createdDocumentName = existingDocumentName
            } else {
                XCTFail()
            }

            creationExpectation.fulfill()
        }

        // then
        wait(for: [creationExpectation], timeout: Constants.defaultTimeout)

        var createdDocument: DocumentProtocol!

        let fetchingExpectation = XCTestExpectation()

        // when
        let query = storage.query(by: createdDocumentName)
        query.fetchFirst(runCompletionIn: .main) { (document, error) in
            if let existingDocument = document, error == nil {
                createdDocument = existingDocument
            } else {
                XCTFail()
            }

            fetchingExpectation.fulfill()
        }

        // then
        wait(for: [fetchingExpectation], timeout: Constants.defaultTimeout)

        let documentNode = createdDocument.rootNode as! DocumentNodeProtocol

        XCTAssertEqual(jsonNode.string(for: "fullName"), documentNode.string(for: "fullName"))
        XCTAssertEqual(jsonNode.integer(for: "votes"), documentNode.integer(for: "votes"))
    }

    func testDocumentCreatedWithMatchingList() {
        // given
        var createdDocumentName: String!

        var rootNode = JSONDocumentNode()

        var nameSubnode = JSONDocumentNode()
        nameSubnode.set(string: "John Gold", for: "fullname")

        var votesSubnode = JSONDocumentNode()
        votesSubnode.set(integer: 10, for: "votes")

        rootNode.set(list: [nameSubnode, votesSubnode], for: "nodes")

        let creationExpectation = XCTestExpectation()

        // when
        storage.create(rootNode, runCompletionIn: .main) { (documentName, error) in
            if let existingDocumentName = documentName, error == nil {
                createdDocumentName = existingDocumentName
            } else {
                XCTFail()
            }

            creationExpectation.fulfill()
        }

        // then
        wait(for: [creationExpectation], timeout: Constants.defaultTimeout)

        var createdDocument: DocumentProtocol!

        let fetchingExpectation = XCTestExpectation()

        // when
        let query = storage.query(by: createdDocumentName)
        query.fetchFirst(runCompletionIn: .main) { (document, error) in
            if let existingDocument = document, error == nil {
                createdDocument = existingDocument
            } else {
                XCTFail()
            }

            fetchingExpectation.fulfill()
        }

        // then
        wait(for: [fetchingExpectation], timeout: Constants.defaultTimeout)

        let documentNode = createdDocument.rootNode as! DocumentNodeProtocol

        guard let list = documentNode.list(for: "nodes"), list.count == 2 else {
            XCTFail()
            return
        }

        XCTAssertEqual(list[0].string(for: "fullname"), "John Gold")
        XCTAssertEqual(list[1].integer(for: "votes"), 10)
    }

    func testUpdateOrderOfTheSameDocument() {
        // given
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullName")
        jsonNode.set(integer: 10, for: "votes")

        var createdDocumentName: String!

        let creationExpectation = XCTestExpectation()

        storage.create(jsonNode, runCompletionIn: .main) { (documentName, error) in
            if let existingDocumentName = documentName, error == nil {
                createdDocumentName = existingDocumentName
            } else {
                XCTFail()
            }

            creationExpectation.fulfill()
        }

        wait(for: [creationExpectation], timeout: Constants.defaultTimeout)

        let fetchingExpectation = XCTestExpectation()

        var existingDocument: DocumentProtocol!

        let query = storage.query(by: createdDocumentName)
        query.fetchFirst(runCompletionIn: .main) { (document, _) in
            if document == nil {
                XCTFail()
            }

            existingDocument = document

            fetchingExpectation.fulfill()
        }

        wait(for: [fetchingExpectation], timeout: Constants.defaultTimeout)

        let numberOfUpdates = 100

        let savingExpectation = XCTestExpectation()
        savingExpectation.expectedFulfillmentCount = numberOfUpdates

        // when
        for _ in 0..<numberOfUpdates {
            jsonNode.set(string: UUID().uuidString, for: "fullName")
            existingDocument.rootNode = jsonNode
            storage.save(document: existingDocument, runCompletionIn: .main) { (error) in
                XCTAssertTrue(error == nil)

                savingExpectation.fulfill()
            }
        }

        wait(for: [savingExpectation], timeout: Constants.defaultTimeout * Double(numberOfUpdates))

        let checkingExpectation = XCTestExpectation()

        let anotherQuery = storage.query(by: createdDocumentName)
        anotherQuery.fetchFirst(runCompletionIn: .main) { (document, _) in
            if document == nil {
                XCTFail()
            }

            existingDocument = document

            checkingExpectation.fulfill()
        }

        wait(for: [checkingExpectation], timeout: Constants.defaultTimeout)

        let documentNode = existingDocument.rootNode as! DocumentNodeProtocol

        XCTAssertEqual(jsonNode.string(for: "fullName"), documentNode.string(for: "fullName"))
    }

    func testManyDocumentsCreationAtSameTime() {
        // given
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullName")
        jsonNode.set(integer: 10, for: "votes")

        let numberOfDocuments = 100

        let creationExpectation = XCTestExpectation()
        creationExpectation.expectedFulfillmentCount = numberOfDocuments

        // when
        for _ in 0..<numberOfDocuments {
            storage.create(jsonNode, runCompletionIn: .main) { (documentName, _) in
                if documentName == nil {
                    XCTFail()
                }

                creationExpectation.fulfill()
            }
        }

        // then
        wait(for: [creationExpectation], timeout: Constants.defaultTimeout * Double(numberOfDocuments))

        let fetchingExpectation = XCTestExpectation()

        let query = storage.queryAll()
        query.fetchAll(runCompletionIn: .main) { (documents, _) in
            XCTAssertEqual(documents!.count, numberOfDocuments)

            for document in documents! {
                let documentNode = document.rootNode as! DocumentNodeProtocol
                XCTAssertEqual(jsonNode.string(for: "fullName"), documentNode.string(for: "fullName"))
                XCTAssertEqual(jsonNode.integer(for: "votes"), documentNode.integer(for: "votes"))
            }

            fetchingExpectation.fulfill()
        }

        wait(for: [fetchingExpectation], timeout: Constants.defaultTimeout * Double(numberOfDocuments))
    }

    func testExistingDocumentRemoval() {
        // given
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullName")
        jsonNode.set(integer: 10, for: "votes")

        var createdDocumentName: String!

        let creationExpectation = XCTestExpectation()

        storage.create(jsonNode, runCompletionIn: .main) { (documentName, error) in
            if let existingDocumentName = documentName, error == nil {
                createdDocumentName = existingDocumentName
            } else {
                XCTFail()
            }

            creationExpectation.fulfill()
        }

        wait(for: [creationExpectation], timeout: Constants.defaultTimeout)

        let removalExpectation = XCTestExpectation()

        storage.removeDocument(with: createdDocumentName, runCompletionIn: .main) { error in
            XCTAssertNil(error)
            removalExpectation.fulfill()
        }

        wait(for: [removalExpectation], timeout: Constants.defaultTimeout)

        let fetchExpectation = XCTestExpectation()

        let query = storage.query(by: createdDocumentName)
        query.fetchFirst(runCompletionIn: .main) { (document, _) in
            XCTAssertNil(document)
            fetchExpectation.fulfill()
        }

        wait(for: [fetchExpectation], timeout: Constants.defaultTimeout)
    }

    func testNotExistingDocumentRemoval() {
        // given
        let removalExpectation = XCTestExpectation()

        // when
        storage.removeDocument(with: UUID().uuidString, runCompletionIn: .main) { error in
            XCTAssertNotNil(error)
            removalExpectation.fulfill()
        }

        wait(for: [removalExpectation], timeout: Constants.defaultTimeout)

        let fetchExpectation = XCTestExpectation()

        let query = storage.queryAll()
        query.fetchAll(runCompletionIn: .main) { (documents, _) in
            XCTAssertEqual(documents?.count, 0)
            fetchExpectation.fulfill()
        }

        wait(for: [fetchExpectation], timeout: Constants.defaultTimeout)
    }
}
