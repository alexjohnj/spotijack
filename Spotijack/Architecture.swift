//
//  Architecture.swift
//  Spotijack
//
//  Created by Alex Jackson on 27/07/2020.
//  Copyright © 2020 Alex Jackson. All rights reserved.
//

import Foundation
import Dispatch
import Combine

// MARK: - Commands

typealias Command<Message> = AnyPublisher<Message, Never>

extension Publisher where Failure == Never {
    func eraseToCommand() -> Command<Output> {
        self.eraseToAnyPublisher()
    }
}

extension Command {
    static var none: Self {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}

// MARK: - Reducer

struct Reducer<State, Message, Environment> {

    private let body: (inout State, Message, Environment) -> Command<Message>

    init(_ body: @escaping (inout State, Message, Environment) -> Command<Message>) {
        self.body = body
    }

    func evaluate(_ state: inout State, _ message: Message, _ environment: Environment) -> Command<Message> {
        return body(&state, message, environment)
    }

    static var none: Reducer<State, Message, Environment> {
        Reducer { _, _, _ in .none }
    }
}

// MARK: - Store

final class Store<State: Equatable, Message> {

    @Published private(set) var state: State
    let publisher: AnyPublisher<State, Never>

    private var isSending = false
    private var effectCancellationMap: [UUID: AnyCancellable] = [:]
    private let reducer: (inout State, Message) -> Command<Message>

    init<Environment>(initialState: State, reducer: Reducer<State, Message, Environment>, environment: Environment) {
        self.state = initialState
        self.reducer = { reducer.evaluate(&$0, $1, environment) }
        self.publisher = _state.projectedValue.removeDuplicates().eraseToAnyPublisher()
    }

    func send(_ message: Message) {
        assert(!isSending, "Store reentrency issue detected! The store was sent a message while another message is being processed.")
        // What really matters is that we're always on the same serial queue but this is an easier check and is right
        // for 99% of cases.
        dispatchPrecondition(condition: .onQueue(.main))

        isSending = true
        let effect = reducer(&state, message)
        isSending = false

        let effectID = UUID()
        var effectIsComplete = false

        let cancellable = effect.sink(
            receiveCompletion: { [weak self] _ in
                self?.effectCancellationMap.removeValue(forKey: effectID)
                effectIsComplete = true
            },
            receiveValue: { [weak self] message in
                // FIXME: There is potential for a stack overflow here if combining _lots_ of synchronous commands
                // together. This can be changed from a recursive function call to a loop to fix it.
                self?.send(message)
            }
        )

        // Synchronous effects will complete immediately upon subscription so there's no point storing their
        // cancellable.
        if !effectIsComplete {
            effectCancellationMap[effectID] = cancellable
        }
    }
}
