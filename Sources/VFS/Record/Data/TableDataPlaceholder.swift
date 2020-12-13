//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 9.12.20.
//

import Foundation

public
struct TableDataPlaceholder<Info: RecordInfo, Reader: AsyncReader>: DataPlaceholder {
    public let record: Info
    public let reader: Reader

    public
    init(record: Info, reader: Reader) {
        self.record = record
        self.reader = reader
    }
}
