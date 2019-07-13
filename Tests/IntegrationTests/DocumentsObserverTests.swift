/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
import SoraDocuments

class DocumentsObserverTests: DocumentsStorageBaseTests {

    func testAllValidCombination() {
        for rawValue in 1..<8 {
            let changes = DocumentsStorageChanges(rawValue: UInt8(rawValue))

            let name = performCreate()
            performTest(name: name, changes: changes)

            clearDocumentsDirectory()
        }
    }

    func testRegisterUnregisterSubscription() {
        let query = self.storage.queryAll()
        let subscriptionId = query.subscribe(observer: DocumentsObserver(block: { _, _ in}, queue: .main, changes: [.created]))

        let additionalSubscribersCount = 10
        for _ in 0..<additionalSubscribersCount {
            _ = query.subscribe(observer: DocumentsObserver(block: { _, _ in}, queue: .main, changes: [.created]))
        }

        self.performCreate()
        self.performCreate()
        self.performCreate()

        query.fetchAll(runCompletionIn: .main, with: { _, _ in })
        query.fetchFirst(runCompletionIn: .main, with: { _, _ in })

        XCTAssertTrue(self.fetchSubscriptionIds().contains(subscriptionId))

        query.unsubscribe(subscriptionId: subscriptionId)

        let subscriptions = self.fetchSubscriptionIds()

        XCTAssertTrue(!subscriptions.contains(subscriptionId))
        XCTAssertEqual(subscriptions.count, additionalSubscribersCount)
    }

    func testUnregisterSubscriptionOnRelease() {
        autoreleasepool {
            let query = self.storage.queryAll()
            let subscriptionId = query.subscribe(observer: DocumentsObserver(block: { _, _ in}, queue: .main, changes: [.created]))

            self.performCreate()
            self.performCreate()
            self.performCreate()

            query.fetchAll(runCompletionIn: .main, with: { _, _ in })
            query.fetchFirst(runCompletionIn: .main, with: { _, _ in })

            XCTAssertTrue(self.fetchSubscriptionIds().contains(subscriptionId))
        }

        guard let documentsStorage = storage as? DocumentsStorage else {
            XCTFail()
            return
        }

        let waitingQueue = DispatchQueue(label: "polling", qos: .default, attributes: .concurrent)

        let semaphore = DispatchSemaphore(value: 0)

        waitingQueue.async {
            var isCompleted = false

            while(!isCompleted) {
                let innerSemaphore = DispatchSemaphore(value: 0)

                documentsStorage.fetchSubscriptionIds(runInCompletion: waitingQueue) { (subscriptions) in
                    isCompleted = subscriptions.isEmpty
                    innerSemaphore.signal()
                }

                guard case .success = innerSemaphore.wait(timeout: .now() + .seconds(Int(Constants.defaultTimeout))) else {
                    XCTFail()
                    return
                }
            }

            semaphore.signal()
        }

        guard case .success = semaphore.wait(timeout: .now() + .seconds(Int(Constants.defaultTimeout))) else {
            XCTFail()
            return
        }
    }

    // MARK: Private

    private func performTest(name: String, changes: DocumentsStorageChanges) {
        let expectation = XCTestExpectation()
        var expectationsCount = 0

        let allRawValues = [DocumentsStorageChanges.created.rawValue, DocumentsStorageChanges.updated.rawValue, DocumentsStorageChanges.removed.rawValue]

        for rawValue in allRawValues {
            let change  = DocumentsStorageChanges(rawValue: rawValue)
            if changes.contains(change) {
                expectationsCount += 1
            }
        }

        expectation.expectedFulfillmentCount = expectationsCount

        let subscriptionBlock = { (name: String, change: DocumentsStorageChanges) in
            if changes.isSuperset(of: change) {
                expectation.fulfill()
            } else {
                XCTFail()
            }
        }

        let query = storage.queryAll()
        _ = query.subscribe(observer: DocumentsObserver(block: subscriptionBlock, queue: .main, changes: changes))

        if changes.contains(.created) {
            performCreate()
        }

        if changes.contains(.updated) {
            performUpdate(name: name)
        }

        if changes.contains(.removed) {
            performRemove(name: name)
        }

        wait(for: [expectation], timeout: Constants.defaultTimeout)
    }

    @discardableResult
    private func performCreate() -> String {
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

        return createdDocumentName
    }

    private func performUpdate(name: String) {
        let fetchingExpectation = XCTestExpectation()

        var existingDocument: DocumentProtocol!

        let query = storage.query(by: name)
        query.fetchFirst(runCompletionIn: .main) { (document, _) in
            if document == nil {
                XCTFail()
            }

            existingDocument = document

            fetchingExpectation.fulfill()
        }

        wait(for: [fetchingExpectation], timeout: Constants.defaultTimeout)

        let savingExpectation = XCTestExpectation()

        storage.save(document: existingDocument, runCompletionIn: .main) { (error) in
            XCTAssertTrue(error == nil)

            savingExpectation.fulfill()
        }

        wait(for: [savingExpectation], timeout: Constants.defaultTimeout)
    }

    private func performRemove(name: String) {
        let removalExpectation = XCTestExpectation()

        storage.removeDocument(with: name, runCompletionIn: .main) { error in
            XCTAssertNil(error)
            removalExpectation.fulfill()
        }

        wait(for: [removalExpectation], timeout: Constants.defaultTimeout)
    }
}
