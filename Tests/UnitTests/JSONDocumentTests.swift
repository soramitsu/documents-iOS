/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
import SoraDocuments

class JSONDocumentTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAddingAttributes() {
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullname")
        jsonNode.set(integer: 10, for: "votes")
        jsonNode.set(string: "John", for: "firstname")
        jsonNode.set(integer: 100, for: "rating")

        XCTAssertEqual("John Gold", jsonNode.string(for: "fullname"))
        XCTAssertEqual("John", jsonNode.string(for: "firstname"))
        XCTAssertEqual(10, jsonNode.integer(for: "votes"))
        XCTAssertEqual(100, jsonNode.integer(for: "rating"))
    }

    func testRemoveAttributes() {
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullname")
        jsonNode.set(integer: 10, for: "votes")

        XCTAssertEqual("John Gold", jsonNode.string(for: "fullname"))
        XCTAssertEqual(10, jsonNode.integer(for: "votes"))

        jsonNode.remove(for: "fullname")
        jsonNode.remove(for: "votes")

        XCTAssertNil(jsonNode.string(for: "fullname"))
        XCTAssertNil(jsonNode.integer(for: "votes"))
    }

    func testAddReference() {
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullname")
        jsonNode.set(integer: 10, for: "votes")

        let jsonReference = JSONDocumentReference(referenceName: UUID().uuidString)
        jsonNode.set(reference: jsonReference, for: "scan")

        if jsonNode.node(for: "scan") != nil {
            XCTFail()
            return
        }

        guard let retrievedReference = jsonNode.reference(for: "scan") else {
            XCTFail()
            return
        }

        XCTAssertEqual(jsonReference.referenceName, retrievedReference.referenceName)
    }

    func testAddList() {
        var rootNode = JSONDocumentNode()

        var nameSubnode = JSONDocumentNode()
        nameSubnode.set(string: "John Gold", for: "fullname")

        var votesSubnode = JSONDocumentNode()
        votesSubnode.set(integer: 10, for: "votes")

        rootNode.set(list: [nameSubnode, votesSubnode], for: "nodes")

        if rootNode.node(for: "nodes") != nil {
            XCTFail()
            return
        }

        if rootNode.reference(for: "nodes") != nil {
            XCTFail()
            return
        }

        guard let list = rootNode.list(for: "nodes"), list.count == 2 else {
            XCTFail()
            return
        }

        XCTAssertEqual(list[0].string(for: "fullname"), "John Gold")
        XCTAssertEqual(list[1].integer(for: "votes"), 10)
    }

    func testAllKeys() {
        var jsonNode = JSONDocumentNode()
        jsonNode.set(string: "John Gold", for: "fullname")
        jsonNode.set(integer: 10, for: "votes")

        let jsonReference = JSONDocumentReference(referenceName: UUID().uuidString)
        jsonNode.set(reference: jsonReference, for: "scan")

        let keys = jsonNode.allKeys()

        XCTAssertEqual(keys.count, 3)
        XCTAssertTrue(keys.contains("fullname"))
        XCTAssertTrue(keys.contains("votes"))
        XCTAssertTrue(keys.contains("scan"))
    }
}
