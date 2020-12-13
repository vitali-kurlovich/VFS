//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 26.11.20.
//

import Foundation

public
class DataBase<Info: RecordInfo, Writer: AsyncWriter, Reader: AsyncReader> {
    private var tableCache: [String: AnyObject] = [:]

    func table<Meta: Codable>(_: Meta.Type, name: String,
                              recordsReader: Reader,
                              recordsWriter: Writer,
                              dataStoreReader: Reader,
                              dataStoreWriter: Writer) -> Table<Meta, Info, Writer, Reader>?
    {
        if let table = tableCache[name] as? Table<Meta, Info, Writer, Reader> {
            return table
        }

        let table = Table<Meta, Info, Writer, Reader>(recordsReader: recordsReader, recordsWriter: recordsWriter, dataStoreReader: dataStoreReader, dataStoreWriter: dataStoreWriter)

        tableCache[name] = table

        return table
    }
}
