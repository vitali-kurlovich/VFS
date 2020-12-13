//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 8.12.20.
//

import Foundation

public
final class Table<Meta: Codable, Info: RecordInfo, Writer: AsyncWriter, Reader: AsyncReader> {
    internal let recordsInfoStorage: RecordsInfoStorage<Info, Writer, Reader>

    public typealias ResultData = TableDataPlaceholder<Info, Reader>

    private typealias DataStoreType = DataStore<Info, Writer, Reader, ResultData>

    private let dataStore: DataStoreType

    private let metaEncoder = JSONEncoder()
    private let metaDecoder = JSONDecoder()

    private let taskQueue = TaskQueue()

    private var metaChache: [Info.ID: Meta] = [:]

    init(recordsReader: Reader, recordsWriter: Writer, dataStoreReader: Reader, dataStoreWriter: Writer) {
        recordsInfoStorage = RecordsInfoStorage<Info, Writer, Reader>(reader: recordsReader, writer: recordsWriter)
        dataStore = DataStoreType(reader: dataStoreReader, writer: dataStoreWriter)
    }

    private
    func addTask(task: @escaping (TaskQueue.Context) -> Void) {
        taskQueue.addTask(task: task)
    }
}

extension Table {
    enum TableError: Error {
        case notFindById
    }
}

extension Table {
    func select(by id: Info.ID, completion: @escaping (Result<ResultData, Error>) -> Void) {
        addTask { context in

            func select(info: Info) {
                let placeholder = self.dataStore.read(info: info)
                completion(.success(placeholder))
                context.finish()
            }

            self.recordsInfoStorage.select(by: id) { result in
                switch result {
                case let .success(info):
                    guard let info = info else {
                        completion(.failure(TableError.notFindById))
                        context.finish()
                        return
                    }
                    select(info: info)
                case let .failure(error):

                    completion(.failure(error))
                    context.finish()
                }
            }
        }
    }
}

extension Table {
    func delete(by id: Info.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        addTask { context in
            self.recordsInfoStorage.delete(by: id) { result in
                switch result {
                case .success:
                    self.metaChache[id] = nil
                    completion(.success(()))
                    context.finish()

                case let .failure(error):

                    completion(.failure(error))
                    context.finish()
                }
            }
        }
    }
}

extension Table {
    public
    func insert(data: Data, meta: Meta, completion: @escaping (Result<Info.ID, Error>) -> Void) {
        let metaData = (try? metaEncoder.encode(meta)) ?? Data()

        insert(data: data, metaData: metaData) { result in
            switch result {
            case let .success(id):
                self.metaChache[id] = meta

                completion(.success(id))

            case let .failure(error):
                completion(.failure(error))
            }
        }

        // metaChache
    }

    private
    func insert(data: Data, metaData: Data, completion: @escaping (Result<Info.ID, Error>) -> Void) {
        addTask { context in

            // assert(metaData.count < Info._MetaLenght. )

            func appendIndex(newInfo: Info) {
                self.recordsInfoStorage.insert(info: newInfo) { result in
                    switch result {
                    case .success:

                        completion(.success(newInfo.id))
                        context.finish()

                    case let .failure(error):

                        completion(.failure(error))
                        context.finish()
                    }
                }
            }

            func updateStore(newInfo: Info) {
                self.dataStore.write(info: newInfo, data: data, metaData: metaData) { result in
                    switch result {
                    case .success:
                        appendIndex(newInfo: newInfo)
                    case let .failure(error):

                        completion(.failure(error))
                        context.finish()
                    }
                }
            }

            func updateIndex(update: Info?, new: Info) {
                if let update = update {
                    self.recordsInfoStorage.update(info: update) { result in
                        switch result {
                        case .success:
                            updateStore(newInfo: new)
                        case let .failure(error):

                            completion(.failure(error))
                            context.finish()
                        }
                    }
                } else {
                    updateStore(newInfo: new)
                }
            }

            self.recordsInfoStorage.newRecord(for: .init(data.count), metaSize: .init(metaData.count)) { result in
                switch result {
                case let .success((update, new)):
                    updateIndex(update: update, new: new)
                case let .failure(error):

                    completion(.failure(error))
                    context.finish()
                }
            }
        }
    }
}

extension Table {
    func readData(info: Info) -> ResultData {
        dataStore.read(info: info)
    }
}

extension Table {
    func readMeta(info: Info, completion: @escaping (Result<Meta, Error>) -> Void) {
        addTask { context in

            if let meta = self.metaChache[info.id] {
                completion(.success(meta))
                context.finish()
                return
            }

            self.dataStore.readMeta(info: info) { result in

                defer {
                    context.finish()
                }

                switch result {
                case let .success(data):

                    do {
                        let meta = try self.metaDecoder.decode(Meta.self, from: data)
                        self.metaChache[info.id] = meta
                        completion(.success(meta))
                    } catch {
                        completion(.failure(error))
                    }

                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }

    func readMeta<Records: Sequence>(records: Records,
                                     completion: @escaping (Result<[Meta], Error>) -> Void) where Records.Element == Info
    {
        var result: [Meta] = []
        result.reserveCapacity(records.underestimatedCount)

        readMeta(iterator: records.makeIterator(), accumulator: result, completion: completion)
    }

    private
    func readMeta<Iterator: IteratorProtocol>(iterator: Iterator,
                                              accumulator: [Meta],
                                              completion: @escaping (Result<[Meta], Error>) -> Void) where Iterator.Element == Info
    {
        var iterator = iterator
        guard let info = iterator.next() else {
            completion(.success(accumulator))
            return
        }

        readMeta(info: info) { result in
            switch result {
            case let .success(meta):
                var array = accumulator
                array.append(meta)
                self.readMeta(iterator: iterator, accumulator: array, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
