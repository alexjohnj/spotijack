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
import os.log

// An implementation of The Elm Architecture/Redux/Flux/$UNIDIRECTIONAL_DATA_FLOW. The implementation is based on
// the ideas described by the Point-Free (http://pointfree.co) guys and is _eerily_ similar to their TCA library to the
// point at which I probably should've just used that instead. Nonetheless this was fun to write and only took around
// half an hour.

// MARK: - Commands

typealias Command<Message> = AnyPublisher<Message, Never>

extension Publisher where Failure == Never {
    func eraseToCommand() -> Command<Output> {
        self.eraseToAnyPublisher()
    }
}

extension Command {

    static func just(value: Output) -> Command<Output> {
        Just<Output>(value).eraseToCommand()
    }

    static var none: Self {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }

    static func sequence(_ commands: Command<Output>...) -> Command<Output> {
        sequence(commands)
    }

    static func sequence<C: Collection>(_ commands: C) -> Command<Output> where C.Element == Command<Output> {
        guard let firstCommand = commands.first else { return .none }

        return commands.dropFirst()
            .reduce(into: firstCommand) { (combinedCommands: inout Command<Output>, command: Command<Output>) in
                combinedCommands = combinedCommands.append(command).eraseToCommand()
            }
    }

    static func merge(_ commands: Command<Output>...) -> Command<Output> {
        return merge(commands)
    }

    static func merge<C: Collection>(_ commands: C) -> Command<Output> where C.Element == Command<Output> {
        return Publishers.MergeMany(commands).eraseToCommand()
    }

    static func future<Failure: Error>(_ work: @escaping (@escaping (Result<Output, Failure>) -> Void) -> Void) -> Command<Result<Output, Failure>> {
        Deferred {
            Future { promise in
                work { promise($0) }
            }
        }
        .catchCommand()
    }

    static func fireAndForget(_ work: @escaping () -> Void) -> Command<Output> {
        return Deferred { () -> Empty<Output, Never> in
            work()
            return Empty(completeImmediately: true)
        }
        .eraseToCommand()
    }

    static func catching(_ work: @escaping () throws -> Output) -> Command<Result<Output, Error>> {
        return Deferred { () -> AnyPublisher<Output, Error> in
            do {
                let output = try work()
                return Just(output).setFailureType(to: Error.self).eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .catchCommand()
    }
}

extension Command where Output == Never, Failure == Never {
    func fireAndForget<NewOutput>() -> Command<NewOutput> {
        func absurd<A>(_ value: Never) -> A { }
        return self.map(absurd(_:)).eraseToCommand()
    }
}

extension Publisher {
    func catchCommand() -> Command<Result<Output, Failure>> {
        return self.map(Result.success)
            .catch { Just(.failure($0)) }
            .eraseToCommand()
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

    func debugMessages() -> Reducer<State, Message, Environment> {
        return Reducer { state, message, env in
            os_log(.debug, "Received Message: %s", String(describing: message))
            return self.evaluate(&state, message, env)
        }
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
