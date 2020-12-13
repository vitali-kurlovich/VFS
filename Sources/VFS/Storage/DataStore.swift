//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 8.12.20.
//

import Foundation

internal
final class DataStore<Info, Writer: AsyncWriter, Reader, ResultData: DataPlaceholder> where ResultData.Info == Info, ResultData.Reader == Reader {
    private let writer: Writer
    private let reader: Reader

    internal
    init(reader: Reader, writer: Writer) {
        self.reader = reader
        self.writer = writer
    }

    func read(info: Info) -> ResultData {
        ResultData(record: info, reader: reader)
    }

    func readMeta(info: Info, completion: @escaping (Result<Data, Error>) -> Void) {
        guard info.metaSize != 0 else {
            completion(.success(Data()))
            return
        }

        reader.read(offset: Int(info.offset), lenght: Int(info.metaSize)) { result in

            switch result {
            case let .success(data):
                completion(.success(data))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func write(info: Info, data: Data, metaData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        assert(info.size == data.count)
        assert(info.metaSize == metaData.count)

        if metaData.isEmpty {
            writer.write(offset: Int(info.offset), data: data) { result in
                switch result {
                case .success():
                    completion(.success(()))
                case let .failure(error):
                    completion(.failure(error))
                }
            }

        } else {
            writer.write(offset: Int(info.offset), data: metaData) { result in
                switch result {
                case .success:
                    self.writer.write(offset: Int(info.offset) + Int(info.metaSize), data: data) { result in
                        switch result {
                        case .success:
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
    }
}
