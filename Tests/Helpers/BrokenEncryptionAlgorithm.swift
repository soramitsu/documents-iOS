/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import SoraDocuments

class BrokenEncryptionAlgorithm: DocumentEncryptionAlgorithmProtocol {
    func encrypt(data: Data) throws -> Data {
        let half = data.count / 2
        return data[half...]
    }

    func decrypt(data: Data) throws -> Data {
        let half = data.count / 2
        return data[half...]
    }
}
