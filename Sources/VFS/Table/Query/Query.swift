//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 10.12.20.
//

import Foundation

public
protocol Query {
    var skip: Int? { get }
    var limit: Int? { get }
}

public
protocol FilterQuery: Query {
    associatedtype Meta
    func filter(_ isIncluded: Meta) -> Bool
}

public
protocol OrderQuery: FilterQuery {
    func compare(_ left: Meta, _ right: Meta) -> Bool
}

public
extension OrderQuery {
    func compare(_ left: Meta, _ right: Meta) -> Bool where Meta: Comparable {
        left < right
    }

    func filter(_: Meta) -> Bool {
        true
    }
}

public
protocol QueryResult {
    associatedtype Placeholder: DataPlaceholder
    associatedtype Meta: Codable

    var meta: Meta { get }
    var data: Placeholder { get }
}
