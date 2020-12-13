//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 8.12.20.
//

import Foundation

// RecordsInfoStorage+Enumerator

internal
class RecordsInfoStorage<Info: RecordInfo, Writer: AsyncWriter, Reader: AsyncReader>: RecordsInfoContext {
    enum ContextError: Error {
        case notUniqId
        case notFound
    }

    private let writer: Writer
    private let reader: Reader

    private let decoder = DataBaseRecordInfoDecoder<Info>()
    private let encoder = DataBaseRecordInfoEncoder<Info>()

    private var cachedRecords: [Info] = []
    private var isCacheLoaded = false

    init(reader: Reader, writer: Writer) {
        self.writer = writer
        self.reader = reader
    }

    private
    func loadRecords(completion: @escaping (Result<[Info], Error>) -> Void) {
        reader.readAll { result in
            switch result {
            case let .success(data):
                let records = self.decoder.decode(from: data)
                completion(.success(records))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func selectAll(completion: @escaping (Result<[Info], Error>) -> Void) {
        if isCacheLoaded {
            completion(.success(cachedRecords))
        } else {
            loadRecords { result in
                switch result {
                case let .success(records):
                    self.cachedRecords = records
                    self.isCacheLoaded = true
                    completion(.success(records))

                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }

    func select(by id: Info.ID, completion: @escaping (Result<Info?, Error>) -> Void) {
        func select(by id: Info.ID, from records: [Info]) {
            let selected = records.first { (info) -> Bool in
                info.id == id
            }

            completion(.success(selected))
        }

        selectAll { result in
            switch result {
            case let .success(records):
                select(by: id, from: records)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }



    func insert(info: Info, completion: @escaping (Result<Void, Error>) -> Void) {
        selectAll { result in
            switch result {
            case let .success(records):

                guard !records.contains(where: { $0.id == info.id }) else {
                    completion(.failure(ContextError.notUniqId))
                    return
                }

                let byteOffset = self.encoder.memoryLayoutSize * records.count
                let data = self.encoder.encode(info: info)

                self.writer.write(offset: byteOffset, data: data) { result in
                    switch result {
                    case .success:
                        self.cachedRecords.append(info)
                        completion(.success(()))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func insertOfUpdate(info: Info, completion: @escaping (Result<Void, Error>) -> Void) {
        selectAll { result in
            switch result {
            case let .success(records):

                if records.contains(where: { $0.id == info.id }) {
                    self.update(info: info, completion: completion)
                } else {
                    self.insert(info: info, completion: completion)
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func update(info: Info, completion: @escaping (Result<Void, Error>) -> Void) {
        selectAll { result in
            switch result {
            case let .success(records):

                guard let index = records.firstIndex(where: { (record) -> Bool in
                    record.id == info.id
                }) else {
                    completion(.failure(ContextError.notFound))
                    return
                }

                if records[index] == info {
                    completion(.success(()))
                    return
                }

                let byteOffset = self.encoder.memoryLayoutSize * index
                let data = self.encoder.encode(info: info)

                self.writer.write(offset: byteOffset, data: data) { result in
                    switch result {
                    case .success:
                        self.cachedRecords[index] = info
                        completion(.success(()))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func replace(source id: Info.ID, by info: Info, completion: @escaping (Result<Void, Error>) -> Void) {
        selectAll { result in
            switch result {
            case let .success(records):

                guard let index = records.firstIndex(where: { (info) -> Bool in
                    info.id == id
                }) else {
                    completion(.success(()))
                    return
                }

                let byteOffset = self.encoder.memoryLayoutSize * index
                let data = self.encoder.encode(info: info)

                self.writer.write(offset: byteOffset, data: data) { result in
                    switch result {
                    case .success:
                        self.cachedRecords[index] = info
                        completion(.success(()))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func newRecord(for size: Info.Lenght, metaSize: Info.MetaLenght, completion: @escaping (Result<(update: Info?, new: Info), Error>) -> Void) {
        selectAll { result in
            switch result {
            case let .success(records):
                let id = (records.last?.id ?? 0) + 1

                if let dest = records.lazy
                    .filter({ $0.isDeleted && ($0.size + Info.Lenght($0.metaSize)) >= (size + Info.Lenght(metaSize)) })
                    .min(by: { a, b in a.size + Info.Lenght(a.metaSize) < b.size + Info.Lenght(b.metaSize) })
                {
                    let offset = dest.offset

                    let index = Info(id: id, offset: offset, size: size, metaSize: metaSize, isDeleted: false)
                    let update = Info(id: dest.id,
                                      offset: dest.offset + (Info.Offset(size) + Info.Offset(metaSize)),
                                      size: (dest.size + Info.Lenght(dest.metaSize)) - (size + Info.Lenght(metaSize)),
                                      metaSize: 0,
                                      isDeleted: true)

                    completion(.success((update: update, new: index)))

                } else {
                    let offset = records.lazy.map { (index) -> Info.Offset in
                        index.offset + Info.Offset(index.size) + Info.Offset(index.metaSize)
                    }.max() ?? 0

                    let index = Info(id: id, offset: offset, size: size, metaSize: metaSize, isDeleted: false)

                    completion(.success((update: nil, new: index)))
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}


extension RecordsInfoStorage {
    func delete(by id: Info.ID, completion: @escaping (Result<Void, Error>) -> Void) {
        selectAll { result in
            switch result {
            case let .success(records):

                guard let index = records.firstIndex(where: { (info) -> Bool in
                    info.id == id
                }) else {
                    completion(.success(()))
                    return
                }

                let info = records[index]
                let size = info.size + Info.Lenght(info.metaSize)
                let deleted = Info(id: id, offset: info.offset, size: size, metaSize: 0, isDeleted: true)

                let byteOffset = self.encoder.memoryLayoutSize * index
                let data = self.encoder.encode(info: deleted)

                self.writer.write(offset: byteOffset, data: data) { result in
                    switch result {
                    case .success:
                        self.cachedRecords[index] = deleted
                        completion(.success(()))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func delete<S:Sequence>(by ids:S , completion: @escaping (Result<Void, Error>) -> Void) where S.Element == Info {
        selectAll { result in
            switch result {
            case let .success(records):
                break
//                for (index, value) in records.enumerated() {
//                    if ids.contains(<#T##element: RecordInfo##RecordInfo#>)
//                }
                

                /*
                guard let index = records.firstIndex(where: { (info) -> Bool in
                    info.id == id
                }) else {
                    completion(.success(()))
                    return
                }

                let info = records[index]
                let size = info.size + Info.Lenght(info.metaSize)
                let deleted = Info(id: id, offset: info.offset, size: size, metaSize: 0, isDeleted: true)

                let byteOffset = self.encoder.memoryLayoutSize * index
                let data = self.encoder.encode(info: deleted)

                self.writer.write(offset: byteOffset, data: data) { result in
                    switch result {
                    case .success:
                        self.cachedRecords[index] = deleted
                        completion(.success(()))
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
 */

            case let .failure(error):
                completion(.failure(error))
            }
            
        }
    }
}
