//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 11.12.20.
//

import Foundation

public
extension Table {
    struct SelectQuery: Query {
        public let skip: Int?
        public let limit: Int?
    }

    struct SelectFilterQuery: FilterQuery {
        public let skip: Int?
        public let limit: Int?

        let condition: (_ isIncluded: Meta) -> Bool

        public
        func filter(_ isIncluded: Meta) -> Bool {
            condition(isIncluded)
        }
    }

    struct SelectOrderQuery: OrderQuery where Meta: Comparable {
        public let skip: Int?
        public let limit: Int?
    }

    struct SelectOrderWithClosureQuery: OrderQuery {
        public let skip: Int?
        public let limit: Int?

        let order: (_ left: Meta, _ right: Meta) -> Bool

        public func compare(_ left: Meta, _ right: Meta) -> Bool {
            order(left, right)
        }
    }

    struct SelectFilterWithOrderQuery: OrderQuery {
        public let skip: Int?
        public let limit: Int?
        let condition: (_ isIncluded: Meta) -> Bool
        let order: (_ left: Meta, _ right: Meta) -> Bool

        public
        func compare(_ left: Meta, _ right: Meta) -> Bool {
            order(left, right)
        }

        public
        func filter(_ isIncluded: Meta) -> Bool {
            condition(isIncluded)
        }
    }
}

public
extension Table.SelectQuery {
    func filter(condition: @escaping (_ isIncluded: Meta) -> Bool) -> Table.SelectFilterQuery {
        .init(skip: skip, limit: limit, condition: condition)
    }

    func order() -> Table.SelectOrderQuery where Meta: Comparable {
        .init(skip: skip, limit: limit)
    }

    func order(by: @escaping (_ left: Meta, _ right: Meta) -> Bool) -> Table.SelectOrderWithClosureQuery {
        .init(skip: skip, limit: limit, order: by)
    }

    func order<T: Comparable>(by keyPath: KeyPath<Meta, T>) -> Table.SelectOrderWithClosureQuery {
        .init(skip: skip, limit: limit) { (left, right) -> Bool in
            left[keyPath: keyPath] < right[keyPath: keyPath]
        }
    }
}

public
extension Table.SelectFilterQuery {
    func order(by: @escaping (_ left: Meta, _ right: Meta) -> Bool) -> Table.SelectFilterWithOrderQuery {
        .init(skip: skip, limit: limit, condition: condition, order: by)
    }

    func order() -> Table.SelectFilterWithOrderQuery where Meta: Comparable {
        .init(skip: skip, limit: limit, condition: condition, order: { left, right in left < right })
    }

    func order<T: Comparable>(by keyPath: KeyPath<Meta, T>) -> Table.SelectFilterWithOrderQuery {
        .init(skip: skip, limit: limit, condition: condition) { (left, right) -> Bool in
            left[keyPath: keyPath] < right[keyPath: keyPath]
        }
    }
}
