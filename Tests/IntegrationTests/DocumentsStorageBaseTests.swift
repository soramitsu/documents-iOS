/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
import SoraDocuments

class DocumentsStorageBaseTests: XCTestCase {
    var storage: DocumentsStorageProtocol!

    var configuration: DocumentsStorageConfigurationProtocol = {
        let encryptionAlgorithm = IdentityEncryptionAlgorithm()
        var config = DocumentsStorageConfiguration.defaultConfiguration()
        config.encryptionAlgoritm = encryptionAlgorithm
        config.excludeFromiCloudBackup = true
        return config
    }()

    var userDirectoryURL: URL {
        return configuration.documentsURL!.appendingPathComponent(storage.name)
    }

    override func setUp() {
        super.setUp()

        DocumentsStorageManager.shared.configuration = configuration
        storage = DocumentsStorageManager.shared.documentsStorage(for: Constants.dummyUsername)

        clearDocumentsDirectory()
    }

    override func tearDown() {
        clearDocumentsDirectory()

        super.tearDown()
    }

    func saveDocumentNode(node: Any) -> String? {
        let expectation = XCTestExpectation()

        var createdName: String?

        storage.create(node, runCompletionIn: .main) { (name, _) in
            createdName = name
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.defaultTimeout)

        return createdName
    }

    func fetchDocument(with name: String) -> DocumentProtocol? {
        let expectation = XCTestExpectation()

        var fetchedDocument: DocumentProtocol?

        let query = storage.query(by: name)
        query.fetchFirst(runCompletionIn: .main) { (document, _) in
            fetchedDocument = document
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.defaultTimeout)

        return fetchedDocument
    }

    func fetchDocument(with query: DocumentsQueryProtocol) -> DocumentProtocol? {
        let expectation = XCTestExpectation()

        var fetchedDocument: DocumentProtocol?

        query.fetchFirst(runCompletionIn: .main) { (document, _) in
            fetchedDocument = document
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.defaultTimeout)

        return fetchedDocument
    }

    func fetchSubscriptionIds() -> Set<String> {
        guard let documentsStorage = storage as? DocumentsStorage else {
            return Set<String>()
        }

        let expectation = XCTestExpectation()

        var fetchedIds: Set<String>!

        documentsStorage.fetchSubscriptionIds(runInCompletion: .main) { subscriptionIds in
            fetchedIds = subscriptionIds
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.defaultTimeout)

        return fetchedIds
    }

    func setupNew(configuration: DocumentsStorageConfigurationProtocol) {
        DocumentsStorageManager.shared.closeDocumentsStorage(for: Constants.dummyUsername)
        DocumentsStorageManager.shared.configuration = configuration
        storage = DocumentsStorageManager.shared.documentsStorage(for: Constants.dummyUsername)
    }

    func clearDocumentsDirectory() {
        try? FileManager.default.removeItem(at: userDirectoryURL)
    }
}
