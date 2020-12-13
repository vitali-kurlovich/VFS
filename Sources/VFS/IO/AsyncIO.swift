//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 8.12.20.
//

import Foundation

public
protocol AsyncWriter {
    func write(offset: Int,
               data: Data,
               completion: @escaping (Result<Void, Error>) -> Void)
}

public
protocol AsyncReader {
    func read(offset: Int, lenght: Int, completion: @escaping (Result<Data, Error>) -> Void)
    func readAll(completion: @escaping (Result<Data, Error>) -> Void)
}
