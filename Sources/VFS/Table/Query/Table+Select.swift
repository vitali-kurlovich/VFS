//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 10.12.20.
//

import Foundation

public
extension Table {
    struct SelectResult: QueryResult {
        public typealias Placeholder = ResultData
        public let meta: Meta
        public let data: Placeholder
    }
}

// Table+Delete

public
extension Table {
    func select<Select: Query>(_ query: Select, comlation: @escaping (Result<[SelectResult], Error>) -> Void) {
        recordsInfoStorage.selectAll { result in
            switch result {
            case let .success(records):
                let records = records.lazy.filter { !$0.isDeleted }

                let skip = query.skip ?? 0

                guard skip < records.count else {
                    comlation(.success([]))
                    return
                }

                var startIndex = records.startIndex
                var endIndex = records.endIndex

                if let index = records.index(records.startIndex, offsetBy: skip, limitedBy: records.endIndex) {
                    startIndex = index
                } else {
                    comlation(.success([]))
                    return
                }

                if let limit = query.limit {
                    let offset = skip + limit

                    if let index = records.index(records.startIndex, offsetBy: offset, limitedBy: records.endIndex) {
                        endIndex = index
                    }
                }

                let recordsSlice = records[startIndex ..< endIndex]

                self.readMeta(records: recordsSlice) { result in
                    switch result {
                    case let .success(meta):

                        let result = zip(recordsSlice, meta).map { (item) -> SelectResult in
                            .init(meta: item.1, data: self.readData(info: item.0))
                        }

                        comlation(.success(result))

                    case let .failure(error):
                        comlation(.failure(error))
                    }
                }

            case let .failure(error):
                comlation(.failure(error))
            }
        }
    }
}

public
extension Table {
    func select<Select: FilterQuery>(_ query: Select, comlation: @escaping (Result<[SelectResult], Error>) -> Void) where Select.Meta == Meta {
        recordsInfoStorage.selectAll { result in
            switch result {
            case let .success(records):
                let records = records.lazy.filter { !$0.isDeleted }

                let skip = query.skip ?? 0

                guard skip < records.count else {
                    comlation(.success([]))
                    return
                }

                self.readMeta(records: records) { result in
                    switch result {
                    case let .success(meta):
                        let filtered = zip(records, meta).filter { (item) -> Bool in
                            query.filter(item.1)
                        }

                        var startIndex = filtered.startIndex
                        var endIndex = filtered.endIndex

                        if let index = filtered.index(filtered.startIndex, offsetBy: skip, limitedBy: filtered.endIndex) {
                            startIndex = index
                        } else {
                            comlation(.success([]))
                            return
                        }

                        if let limit = query.limit {
                            let offset = skip + limit

                            if let index = filtered.index(filtered.startIndex, offsetBy: offset, limitedBy: filtered.endIndex) {
                                endIndex = index
                            }
                        }

                        let filteredSlice = filtered[startIndex ..< endIndex]

                        let result = filteredSlice.map { (item) -> SelectResult in
                            .init(meta: item.1, data: self.readData(info: item.0))
                        }

                        comlation(.success(result))

                    case let .failure(error):
                        comlation(.failure(error))
                    }
                }

            case let .failure(error):
                comlation(.failure(error))
            }
        }
    }
}

public
extension Table {
    func select<Select: OrderQuery>(_ query: Select, comlation: @escaping (Result<[SelectResult], Error>) -> Void) where Select.Meta == Meta {
        recordsInfoStorage.selectAll { result in
            switch result {
            case let .success(records):
                let records = records.lazy.filter { !$0.isDeleted }

                let skip = query.skip ?? 0

                guard skip < records.count else {
                    comlation(.success([]))
                    return
                }

                self.readMeta(records: records) { result in
                    switch result {
                    case let .success(meta):
                        var filtered = zip(records, meta).filter { (item) -> Bool in
                            query.filter(item.1)
                        }

                        filtered.sort { (left, right) -> Bool in
                            query.compare(left.1, right.1)
                        }

                        var startIndex = filtered.startIndex
                        var endIndex = filtered.endIndex

                        if let index = filtered.index(filtered.startIndex, offsetBy: skip, limitedBy: filtered.endIndex) {
                            startIndex = index
                        } else {
                            comlation(.success([]))
                            return
                        }

                        if let limit = query.limit {
                            let offset = skip + limit

                            if let index = filtered.index(filtered.startIndex, offsetBy: offset, limitedBy: filtered.endIndex) {
                                endIndex = index
                            }
                        }

                        let filteredSlice = filtered[startIndex ..< endIndex]

                        let result = filteredSlice.map { (item) -> SelectResult in
                            .init(meta: item.1, data: self.readData(info: item.0))
                        }

                        comlation(.success(result))

                    case let .failure(error):
                        comlation(.failure(error))
                    }
                }

            case let .failure(error):
                comlation(.failure(error))
            }
        }
    }
}
