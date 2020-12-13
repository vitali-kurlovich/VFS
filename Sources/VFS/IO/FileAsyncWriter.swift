//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 8.12.20.
//

import DispatchIOWrapper
import Foundation

public
final class FileAsyncWriter: AsyncWriter {
    private let file: RandomAccessFile

    public
    init(file: RandomAccessFile) {
        self.file = file
    }

    public
    func write(offset: Int, data: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        file.write(offset: offset, data: data) { result in
            switch result {
            case .success():
                completion(.success(()))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
