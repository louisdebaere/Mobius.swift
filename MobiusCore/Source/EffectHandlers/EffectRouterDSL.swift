// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

public extension EffectRouter where Effect: Equatable {
    /// Add a route for effects which are equal to `constant`.
    ///
    /// - Parameter `constant`: the effect that should be handled by this route.
    func routeEffects(
        equalTo constant: Effect
    ) -> _PartialEffectRouter<Effect, Effect, Event> {
        return routeEffects(withParameters: { effect in effect == constant ? effect : nil })
    }
}

public extension _PartialEffectRouter {
    /// Route to the anonymous  `EffectHandler` defined by the `handle` closure.
    ///
    /// - Parameter handle: A closure which defines an `EffectHandler`.
    func to(
        _ handle: @escaping (EffectParameters, EffectCallback<Event>) -> Disposable
    ) -> EffectRouter<Effect, Event> {
        return to(AnyEffectHandler(handle: handle))
    }

    /// Route to a side-effecting closure.
    ///
    /// - Parameter fireAndForget: a function which given some input carries out a side effect.
    func to(
        _ fireAndForget: @escaping (EffectParameters) -> Void
    ) -> EffectRouter<Effect, Event> {
        return to { parameters, callback in
            fireAndForget(parameters)
            callback.end()
            return AnonymousDisposable {}
        }
    }

    /// Route to a `@MainActor` side-effecting closure.
    ///
    /// The compiler will choose this overload when the closure body touches `@MainActor`-isolated state.
    ///
    /// - Precondition: This route should be bound to `.main` with `.on(queue: .main)`. If not,
    ///   `MainActor.assumeIsolated` traps at runtime.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func to(
        _ fireAndForget: @MainActor @Sendable @escaping (EffectParameters) -> Void
    ) -> EffectRouter<Effect, Event> {
        return to { parameters, callback in
            MainActor.assumeIsolated {
                fireAndForget(parameters)
            }
            callback.end()
            return AnonymousDisposable {}
        }
    }

    /// Route to a closure which returns an optional event when given the parameters as input.
    ///
    /// - Parameter eventClosure: a function which returns an optional event given some input. No events will be
    ///   propagated if this function returns `nil`.
    func toEvent(
        _ eventClosure: @escaping (EffectParameters) -> Event?
    ) -> EffectRouter<Effect, Event> {
        return to { parameters, callback in
            if let event = eventClosure(parameters) {
                callback.send(event)
            }
            callback.end()
            return AnonymousDisposable {}
        }
    }
}

public extension _PartialEffectRouter where EffectParameters == Void {
    /// Route to a side-effecting closure with no input parameters.
    func to(
        _ fireAndForget: @escaping () -> Void
    ) -> EffectRouter<Effect, Event> {
        return to { _, callback in
            fireAndForget()
            callback.end()
            return AnonymousDisposable {}
        }
    }

    /// Route to a `@MainActor` side-effecting closure with no input parameters.
    ///
    /// - Precondition: This route should be bound to `.main` with `.on(queue: .main)`. If not,
    ///   `MainActor.assumeIsolated` traps at runtime.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func to(
        _ fireAndForget: @MainActor @Sendable @escaping () -> Void
    ) -> EffectRouter<Effect, Event> {
        return to { _, callback in
            MainActor.assumeIsolated {
                fireAndForget()
            }
            callback.end()
            return AnonymousDisposable {}
        }
    }
}
