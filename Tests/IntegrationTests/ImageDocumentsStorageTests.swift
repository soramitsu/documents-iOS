/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
import SoraDocuments

class ImageDocumentsStorageTests: DocumentsStorageBaseTests {
    func testNormalImageStore() {
        let image = UIImage.background(from: .red, size: CGSize(width: 400.0, height: 400.0))!

        let savingExpectation = XCTestExpectation()

        var createdName: String!

        storage.create(image, runCompletionIn: .main) { (name, _) in
            XCTAssertNotNil(name)
            createdName = name
            savingExpectation.fulfill()
        }

        wait(for: [savingExpectation], timeout: Constants.defaultTimeout)

        if createdName == nil {
            return
        }

        let query = storage.query(by: createdName)

        let fetchExpectation = XCTestExpectation()

        query.fetchFirst(runCompletionIn: .main) { (document, _) in
            XCTAssertNotNil(document?.rootNode as? UIImage)

            fetchExpectation.fulfill()
        }

        wait(for: [fetchExpectation], timeout: Constants.defaultTimeout)
    }

    func testImageReference() {
        let image = UIImage.background(from: .red, size: CGSize(width: 400.0, height: 400.0))!

        let imageDocName = saveDocumentNode(node: image)
        XCTAssertNotNil(imageDocName)

        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullname")
        jsonNode.set(integer: 10, for: "votes")

        let jsonReference = JSONDocumentReference(referenceName: imageDocName!)
        jsonNode.set(reference: jsonReference, for: "scan")

        let jsonDocName = saveDocumentNode(node: jsonNode)
        XCTAssertNotNil(jsonDocName)

        var jsonDocument = fetchDocument(with: jsonDocName!)

        guard let fetchedJsonNode = jsonDocument?.rootNode as? DocumentNodeProtocol else {
            XCTFail()
            return
        }

        guard let fetchedReference = fetchedJsonNode.reference(for: "scan") else {
            XCTFail()
            return
        }

        let fetchedImageDocument = fetchDocument(with: fetchedReference.documentQuery(in: storage))

        guard let fetchedImage = fetchedImageDocument?.rootNode as? UIImage else {
            XCTFail()
            return
        }

        XCTAssertEqual(image.pngData(), fetchedImage.pngData())
    }
}
