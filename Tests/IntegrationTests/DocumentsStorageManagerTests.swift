/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
import SoraDocuments

class DocumentsStorageManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        DocumentsStorageManager.shared.closeDocumentsStorage(for: Constants.dummyUsername)
    }

    override func tearDown() {
        DocumentsStorageManager.shared.closeDocumentsStorage(for: Constants.dummyUsername)

        super.tearDown()
    }

    func testDocumentsStorageCRUD() {
        XCTAssertFalse(DocumentsStorageManager.shared.isOpenDocumentsStorage(for: Constants.dummyUsername))
        XCTAssertNotNil(DocumentsStorageManager.shared.documentsStorage(for: Constants.dummyUsername))
        XCTAssertTrue(DocumentsStorageManager.shared.isOpenDocumentsStorage(for: Constants.dummyUsername))

        DocumentsStorageManager.shared.closeDocumentsStorage(for: Constants.dummyUsername)

        XCTAssertFalse(DocumentsStorageManager.shared.isOpenDocumentsStorage(for: Constants.dummyUsername))
    }

}
