/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import XCTest
import SoraDocuments

class JSONDocumentCodingTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testJSONEncodeAndDecodeSimpleDocument() {
        // given
        let jsonString = """
{"fullname": "John", "votes": 10, "job": {"title": "My Job"}, "addresses": [{"заголовок": "address1", "photo": {"_id": "123231"}}, {"дом": "address2"}]}
"""
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail()
            return
        }

        let serializer = JSONDocumentSerializer()

        let node = try? serializer.deserialize(data: jsonData)
        guard let jsonNode = node as? JSONDocumentNode else {
            XCTFail()
            return
        }

        // when

        guard let encodedJsonData = try? JSONEncoder().encode(jsonNode) else {
            XCTFail()
            return
        }

        print(String(data: encodedJsonData, encoding: .utf8)!)

        guard let decodedJsonNode = try? JSONDecoder().decode(JSONDocumentNode.self, from: encodedJsonData) else {
            XCTFail()
            return
        }

        XCTAssertEqual(jsonNode, decodedJsonNode)
    }
}
