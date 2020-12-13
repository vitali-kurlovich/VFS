//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 11.12.20.
//

import Foundation

import DispatchIOWrapper

public
final class VirtualFileSystem<Info: RecordInfo> {
    private let filePath: String

    public typealias Reader = FileAsyncReader
    public typealias Writer = FileAsyncWriter

    private let dataBase = DataBase<Info, Writer, Reader>()

    public
    init(rootDir: String) {
        filePath = rootDir
    }

    public
    func table<Meta: Codable>(_ type: Meta.Type, name: String) -> Table<Meta, Info, Writer, Reader>? {
        let pathStore = filePath + "\(name).data"
        let pathRecords = filePath + "\(name).rec"

        guard let storeFile = RandomAccessFile(filePath: pathStore, options: [.createIfNotExists, .readAndWrite]) else {
            return nil
        }

        guard let recordsFile = RandomAccessFile(filePath: pathRecords, options: [.createIfNotExists, .readAndWrite]) else {
            return nil
        }

        let recordsReader = Reader(file: recordsFile)
        let recordsWriter = Writer(file: recordsFile)

        let storeReader = Reader(file: storeFile)
        let storeWriter = Writer(file: storeFile)

        return dataBase.table(type, name: name, recordsReader: recordsReader, recordsWriter: recordsWriter, dataStoreReader: storeReader, dataStoreWriter: storeWriter)
    }
}
