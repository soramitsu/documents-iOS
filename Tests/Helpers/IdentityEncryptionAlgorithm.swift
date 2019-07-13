/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import SoraDocuments

class IdentityEncryptionAlgorithm: DocumentEncryptionAlgorithmProtocol {
    func encrypt(data: Data) throws -> Data {
        return data
    }

    func decrypt(data: Data) throws -> Data {
        return data
    }
}
