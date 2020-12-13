//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 7.12.20.
//

import Foundation

public
final class DataBaseRecordInfoEncoder<Info: RecordInfo>: RecordInfoEncoder, RecordInfoMemoryLayout {
    public var memoryLayoutSize: Int {
        MemoryLayout<Info.ID>.size
            + MemoryLayout<Info.Offset>.size
            + MemoryLayout<Info.Lenght>.size
            + MemoryLayout<Info.MetaLenght>.size
    }

    public func encode(info: Info) -> Data {
        var id = (info.id << 1) | (info.isDeleted ? Info.ID(1) : Info.ID(0))
        var offset = info.offset
        var size = info.size
        var metaSize = info.metaSize

        let byteSize = memoryLayoutSize

        var data = Data()
        data.reserveCapacity(byteSize)

        appendBytes(data: &data, of: &id)
        appendBytes(data: &data, of: &offset)
        appendBytes(data: &data, of: &size)
        appendBytes(data: &data, of: &metaSize)

        return data
    }

    private
    func appendBytes<T>(data: inout Data, of target: inout T) {
        withUnsafeBytes(of: &target) {
            data.append(contentsOf: $0)
        }
    }
}
