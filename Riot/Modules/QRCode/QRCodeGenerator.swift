/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import ZXingObjC

final class QRCodeGenerator {
    enum Error: Swift.Error {
        case cannotCreateImage
    }
    
    func generateCode(from data: Data, with size: CGSize) throws -> UIImage {
        let writer = ZXMultiFormatWriter()
        let endodedString = String(data: data, encoding: .isoLatin1)
        let scale = UIScreen.main.scale
        let bitMatrix = try writer.encode(
            endodedString,
            format: kBarcodeFormatQRCode,
            width: Int32(size.width * scale),
            height: Int32(size.height * scale),
            hints: ZXEncodeHints()
        )
        
        guard let cgImage = ZXImage(matrix: bitMatrix).cgimage else {
            throw Error.cannotCreateImage
        }
        
        return UIImage(cgImage: cgImage)
    }
}
