//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 8.12.20.
//

import Foundation

internal
protocol RecordsInfoContext {
    associatedtype Info: RecordInfo

    func select(by id: Info.ID, completion: @escaping (Result<Info?, Error>) -> Void)
    func delete(by id: Info.ID, completion: @escaping (Result<Void, Error>) -> Void)

    func insert(info: Info, completion: @escaping (Result<Void, Error>) -> Void)

    func insertOfUpdate(info: Info, completion: @escaping (Result<Void, Error>) -> Void)

    func update(info: Info, completion: @escaping (Result<Void, Error>) -> Void)
    func replace(source id: Info.ID, by info: Info, completion: @escaping (Result<Void, Error>) -> Void)

    func selectAll(completion: @escaping (Result<[Info], Error>) -> Void)

    func newRecord(for size: Info.Lenght, metaSize: Info.MetaLenght, completion: @escaping (Result<(update: Info?, new: Info), Error>) -> Void)
}
