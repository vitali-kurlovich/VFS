//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 9.12.20.
//

import Foundation

public
protocol DataPlaceholder {
    associatedtype Info: RecordInfo
    associatedtype Reader: AsyncReader

    var record: Info { get }
    var reader: Reader { get }

    init(record: Info, reader: Reader)
}

public
extension DataPlaceholder {
    var count: Int {
        Int(record.size)
    }
}

public
extension DataPlaceholder {
    func readAll(progressHandler: @escaping (Progress) -> Void,
                 completion: @escaping (Result<Data, Error>) -> Void)
    {
        let offset = Int(record.offset) + Int(record.metaSize)
        let lenght = Int(record.size)

        let progress = Progress(totalUnitCount: Int64(lenght))

        progressHandler(progress)

        reader.read(offset: offset, lenght: lenght) { result in
            switch result {
            case let .success(data):
                progress.completedUnitCount = Int64(lenght)
                progressHandler(progress)

                completion(.success(data))

            case let .failure(error):
                progress.cancel()
                progressHandler(progress)
                completion(.failure(error))
            }
        }
    }

    func readAll(completion: @escaping (Result<Data, Error>) -> Void) {
        let offset = Int(record.offset) + Int(record.metaSize)
        let lenght = Int(record.size)

        reader.read(offset: offset, lenght: lenght, completion: completion)
    }
}

public
extension DataPlaceholder {
    func read(chankSize: Int,
              progressHandler: @escaping (Progress) -> Void,
              readHandler: @escaping (Result<Data?, Error>, _ stop: inout Bool) -> Void)
    {
        let offset = Int(record.offset) + Int(record.metaSize)
        let lenght = Int(record.size)

        let offsets = stride(from: offset, to: offset + lenght, by: chankSize)

        let progress = Progress(totalUnitCount: .init(lenght))
        progressHandler(progress)

        read(iterator: offsets.makeIterator(),
             progress: progress,
             chankSize: chankSize,
             progressHandler: progressHandler,
             readHandler: readHandler)
    }

    func read(chankSize: Int,
              readHandler: @escaping (Result<Data?, Error>, _ stop: inout Bool) -> Void)
    {
        let offset = Int(record.offset) + Int(record.metaSize)
        let lenght = Int(record.size)

        let offsets = stride(from: offset, to: offset + lenght, by: chankSize)

        read(iterator: offsets.makeIterator(),
             chankSize: chankSize,
             readHandler: readHandler)
    }
}

private
extension DataPlaceholder {
    func read<Iterator: IteratorProtocol>(iterator: Iterator,
                                          progress: Progress,
                                          chankSize: Int,
                                          progressHandler: @escaping (Progress) -> Void,
                                          readHandler: @escaping (Result<Data?, Error>, _ stop: inout Bool) -> Void) where Iterator.Element == Int
    {
        var iterator = iterator
        guard let offset = iterator.next() else {
            var stop = false
            readHandler(.success(nil), &stop)
            return
        }

        let end = Int(record.offset) + Int(record.metaSize) + Int(record.size)

        let lenght = end - offset

        let size = lenght > chankSize ? chankSize : lenght

        guard size > 0 else {
            var stop = false
            readHandler(.success(nil), &stop)
            return
        }

        reader.read(offset: offset, lenght: size) { result in
            switch result {
            case let .success(data):
                progress.totalUnitCount += .init(data.count)
                progressHandler(progress)
                var stop = false
                readHandler(.success(data), &stop)

                guard !stop else {
                    progress.cancel()
                    progressHandler(progress)
                    return
                }

                self.read(iterator: iterator, progress: progress, chankSize: chankSize, progressHandler: progressHandler, readHandler: readHandler)

            case let .failure(error):
                progress.cancel()
                progressHandler(progress)
                var stop = false
                readHandler(.failure(error), &stop)
            }
        }
    }

    func read<Iterator: IteratorProtocol>(iterator: Iterator,
                                          chankSize: Int,
                                          readHandler: @escaping (Result<Data?, Error>, _ stop: inout Bool) -> Void) where Iterator.Element == Int
    {
        var iterator = iterator
        guard let offset = iterator.next() else {
            var stop = false
            readHandler(.success(nil), &stop)
            return
        }

        let end = Int(record.offset) + Int(record.metaSize) + Int(record.size)

        let lenght = end - offset

        let size = lenght > chankSize ? chankSize : lenght

        guard size > 0 else {
            var stop = false
            readHandler(.success(nil), &stop)
            return
        }

        reader.read(offset: offset, lenght: size) { result in
            switch result {
            case let .success(data):

                var stop = false
                readHandler(.success(data), &stop)

                guard !stop else {
                    return
                }

                self.read(iterator: iterator, chankSize: chankSize, readHandler: readHandler)
            case let .failure(error):

                var stop = false
                readHandler(.failure(error), &stop)
            }
        }
    }
}
