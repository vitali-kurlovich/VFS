//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 7.12.20.
//

import Foundation

public
protocol RecordInfo: Equatable {
    associatedtype ID: BinaryInteger
    associatedtype Offset: BinaryInteger
    associatedtype Lenght: BinaryInteger
    associatedtype MetaLenght: BinaryInteger

    var id: ID { get }
    var offset: Offset { get }
    var size: Lenght { get }
    var metaSize: MetaLenght { get }
    var isDeleted: Bool { get }

    init(id: ID, offset: Offset, size: Lenght, metaSize: MetaLenght, isDeleted: Bool)
}

internal
struct StoreRecordInfo<ID: BinaryInteger,
    Offset: BinaryInteger,
    Lenght: BinaryInteger,
    MetaLenght: BinaryInteger>: RecordInfo
{
    public let id: ID
    public let offset: Offset
    public let size: Lenght
    public let metaSize: MetaLenght
    public var isDeleted: Bool

    public
    init(id: ID, offset: Offset, size: Lenght, metaSize: MetaLenght, isDeleted: Bool) {
        self.id = id
        self.offset = offset
        self.size = size
        self.metaSize = metaSize
        self.isDeleted = isDeleted
    }
}

public
protocol RecordInfoMemoryLayout {
    var memoryLayoutSize: Int { get }
}

public
protocol RecordInfoEncoder {
    associatedtype Info: RecordInfo
    func encode(info: Info) -> Data
}

public
protocol RecordInfoDecoder {
    associatedtype Info: RecordInfo
    func decode(from data: Data) -> [Info]
}
