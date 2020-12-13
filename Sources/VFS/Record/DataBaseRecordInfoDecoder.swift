//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 7.12.20.
//

import Foundation

public
class DataBaseRecordInfoDecoder<Info: RecordInfo>: RecordInfoDecoder, RecordInfoMemoryLayout {
    public var memoryLayoutSize: Int {
        MemoryLayout<Info.ID>.size
            + MemoryLayout<Info.Offset>.size
            + MemoryLayout<Info.Lenght>.size
            + MemoryLayout<Info.MetaLenght>.size
    }

    public
    func decode(from data: Data) -> [Info] {
        let byteSize = memoryLayoutSize

        let recordCount = data.count / byteSize

        var records: [Info] = []
        records.reserveCapacity(recordCount)

        for index in 0 ..< recordCount {
            let info = decode(data: data, at: index)
            records.append(info)
        }

        return records
    }

    public
    func decode(data: Data, at index: Int) -> Info {
        let indexMemoryLayout = MemoryLayout<Info.ID>.size
            + MemoryLayout<Info.Offset>.size
            + MemoryLayout<Info.Lenght>.size
            + MemoryLayout<Info.MetaLenght>.size

        var byteOffset = index * indexMemoryLayout

        var id = Info.ID()
        read(data: data, offset: byteOffset, MemoryLayout<Info.ID>.size, into: &id)
        byteOffset += MemoryLayout<Info.ID>.size

        var offset = Info.Offset()
        read(data: data, offset: byteOffset, MemoryLayout<Info.Offset>.size, into: &offset)
        byteOffset += MemoryLayout<Info.Offset>.size

        var size = Info.Lenght()
        read(data: data, offset: byteOffset, MemoryLayout<Info.Lenght>.size, into: &size)
        byteOffset += MemoryLayout<Info.Lenght>.size

        var metaSize = Info.MetaLenght()
        read(data: data, offset: byteOffset, MemoryLayout<Info.MetaLenght>.size, into: &metaSize)

        let isDeleted = ((id & 1) != 0)
        id = (id >> 1)

        return Info(id: id, offset: offset, size: size, metaSize: metaSize, isDeleted: isDeleted)
    }

    private
    func read(data: Data, offset: Int, _ byteCount: Int, into: UnsafeMutableRawPointer) {
        data.withUnsafeBytes {
            let from = $0.baseAddress! + offset
            memcpy(into, from, byteCount)
        }
    }
}
