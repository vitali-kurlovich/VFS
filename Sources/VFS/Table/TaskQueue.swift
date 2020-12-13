//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 1.12.20.
//

import Foundation

internal
struct TaskQueue {
    struct Context {
        private let semaphore = DispatchSemaphore(value: 0)

        func finish() {
            semaphore.signal()
        }

        fileprivate
        func wait() {
            semaphore.wait()
        }
    }

    private let queue: DispatchQueue

    init(queue: DispatchQueue = DispatchQueue(label: "DBTaskContext")) {
        self.queue = queue
    }

    func addTask(task: @escaping (Context) -> Void) {
        let context = Context()

        queue.async {
            task(context)
            context.wait()
        }
    }
}
