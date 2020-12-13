//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 13.12.20.
//

import Foundation

// Table+Query
public
extension Table {
    func query(skip: Int? = nil, limit: Int? = nil) -> SelectQuery {
        .init(skip: skip, limit: limit)
    }
}

public
extension Table {
    func query<T: Equatable>(skip: Int? = nil, limit: Int? = nil, where keyPath: KeyPath<Meta, T>, equal to: T) -> SelectFilterQuery {
        SelectFilterQuery(skip: skip, limit: limit) { (meta) -> Bool in
            let value = meta[keyPath: keyPath]
            return value == to
        }
    }

    func query<T: Comparable>(skip: Int? = nil, limit: Int? = nil, where keyPath: KeyPath<Meta, T>, less: T) -> SelectFilterQuery {
        SelectFilterQuery(skip: skip, limit: limit) { (meta) -> Bool in
            let value = meta[keyPath: keyPath]
            return value < less
        }
    }

    func query<T: Comparable>(skip: Int? = nil, limit: Int? = nil, where keyPath: KeyPath<Meta, T>, lessOrEqual: T) -> SelectFilterQuery {
        SelectFilterQuery(skip: skip, limit: limit) { (meta) -> Bool in
            let value = meta[keyPath: keyPath]
            return value <= lessOrEqual
        }
    }

    func query<T: Comparable>(skip: Int? = nil, limit: Int? = nil, where keyPath: KeyPath<Meta, T>, greater: T) -> SelectFilterQuery {
        SelectFilterQuery(skip: skip, limit: limit) { (meta) -> Bool in
            let value = meta[keyPath: keyPath]
            return value > greater
        }
    }

    func query<T: Comparable>(skip: Int? = nil, limit: Int? = nil, where keyPath: KeyPath<Meta, T>, greateOrEqual: T) -> SelectFilterQuery {
        SelectFilterQuery(skip: skip, limit: limit) { (meta) -> Bool in
            let value = meta[keyPath: keyPath]
            return value >= greateOrEqual
        }
    }

    func query<T, RangeExp: RangeExpression>(skip: Int? = nil, limit: Int? = nil, where keyPath: KeyPath<Meta, T>, in range: RangeExp) -> SelectFilterQuery where RangeExp.Bound == T {
        SelectFilterQuery(skip: skip, limit: limit) { (meta) -> Bool in
            let value = meta[keyPath: keyPath]

            return range.contains(value)
        }
    }
}
