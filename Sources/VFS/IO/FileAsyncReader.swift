//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 8.12.20.
//

import DispatchIOWrapper
import Foundation

public
final class FileAsyncReader: AsyncReader {
    private let file: RandomAccessFile

    public
    init(file: RandomAccessFile) {
        self.file = file
    }

    public
    func read(offset: Int, lenght: Int, completion: @escaping (Result<Data, Error>) -> Void) {
        file.read(offset: offset, length: lenght) { result in
            switch result {
            case let .success(data):
                completion(.success(data))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public
    func readAll(completion: @escaping (Result<Data, Error>) -> Void) {
        file.read(offset: 0) { result in
            switch result {
            case let .success(data):
                completion(.success(data))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
