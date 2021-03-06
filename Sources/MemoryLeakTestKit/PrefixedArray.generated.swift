

public struct PrefixedArray<Element, RestElements> {
    public let prefix: Element
    public let rest: RestElements


    public var first: Element {
        return self.prefix
    }


    public var firstAndRest: (Element, RestElements) {
        return (self.first, self.rest)
    }


    public init(prefix: Element, _ rest: RestElements) {
        self.prefix = prefix
        self.rest = rest
    }


    public func dropFirst() -> RestElements {
        return self.rest
    }
}



extension PrefixedArray: Equatable where Element: Equatable, RestElements: Equatable {
    public static func ==(lhs: PrefixedArray<Element, RestElements>, rhs: PrefixedArray<Element, RestElements>) -> Bool {
        return lhs.prefix == rhs.prefix
            && lhs.rest == rhs.rest
    }
}



extension PrefixedArray: Hashable where Element: Hashable, RestElements: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.prefix)
        hasher.combine(self.rest)
    }
}



extension PrefixedArray where RestElements == ArrayLongerThan0<Element> {
    public func sequence() -> ArrayLongerThan1Sequence<Element> {
        return ArrayLongerThan1Sequence<Element>(
            prefix: self.prefix,
            rest: self.rest.sequence()
        )
    }
}
extension PrefixedArray where RestElements == ArrayLongerThan1<Element> {
    public func sequence() -> ArrayLongerThan2Sequence<Element> {
        return ArrayLongerThan2Sequence<Element>(
            prefix: self.prefix,
            rest: self.rest.sequence()
        )
    }
}



public typealias ArrayLongerThan0Sequence<Element> = ArrayLongerThan0<Element>
public typealias ArrayLongerThan1Sequence<Element> = PrefixedArraySequence<Element, ArrayLongerThan0Sequence<Element>>
public typealias ArrayLongerThan2Sequence<Element> = PrefixedArraySequence<Element, ArrayLongerThan1Sequence<Element>>



public struct PrefixedArraySequence<E, RestElements: Sequence>: Sequence where RestElements.Element == E {
    public typealias Element = E


    public let prefix: Element
    public let rest: RestElements


    public init(prefix: Element, rest: RestElements) {
        self.prefix = prefix
        self.rest = rest
    }


    public func makeIterator() -> PrefixedArrayIterator<RestElements> {
        return PrefixedArrayIterator<RestElements>(iterate: self)
    }
}



public class PrefixedArrayIterator<RestElements: Sequence>: IteratorProtocol {
    public typealias Element = RestElements.Element


    private var nextIterator: AnyIterator<Element>? = nil
    private let array: PrefixedArraySequence<Element, RestElements>


    public init(iterate array: PrefixedArraySequence<Element, RestElements>) {
        self.array = array
    }


    public func next() -> Element? {
        guard let nextIterator = self.nextIterator else {
            self.nextIterator = AnyIterator<RestElements.Element>(self.array.rest.makeIterator())
            return self.array.prefix
        }

        let result = nextIterator.next()
        self.nextIterator = nextIterator
        return result
    }
}



public struct PrefixedArrayEnd<Element> {
    private let array: AnyBidirectionalCollection<Element>


    public var startIndex: Int {
        return 0
    }


    public var endIndex: Int {
        return self.count - 1
    }


    public var count: Int {
        return self.array.count
    }


    public var first: Element? {
        return self.array.first
    }


    public var last: Element? {
        return self.array.last
    }


    public var firstAndRest: (Element, PrefixedArrayEnd<Element>)? {
        guard let first = self.first, let rest = self.dropFirst() else {
            return nil
        }

        return (first, rest)
    }


    public init<S: BidirectionalCollection>(
        _ array: S
    ) where S.Element == Element {
        self.array = AnyBidirectionalCollection<Element>(array)
    }


    public init<S: BidirectionalCollection>(
        prefix: Element,
        _ array: S
    ) where S.Element == Element {
        var newArray = Array(array)
        newArray.insert(prefix, at: 0)
        self.init(newArray)
    }


    public init<S: BidirectionalCollection>(
        suffix: Element,
        _ array: S
    ) where S.Element == Element {
        guard let first = array.first else {
            self.init(prefix: suffix, [])
            return
        }

        var newArray = Array(array.dropFirst())
        newArray.append(suffix)

        self.init(prefix: first, newArray)
    }


    public init(_ array: ArrayLongerThan0<Element>) {
        self = array
    }


    public init(_ array: ArrayLongerThan1<Element>) {
        self.init(array.relaxed())
    }
    public init(_ array: ArrayLongerThan2<Element>) {
        self.init(array.relaxed())
    }


    public init(
        suffix: Element,
        _ array: ArrayLongerThan0<Element>
    ) {
        self.init(suffix: suffix, array.relaxed())
    }


    public subscript(index: Int) -> Element {
        let index = self.array.index(self.array.startIndex, offsetBy: index)
        return self.array[index]
    }


    public subscript(range: Range<Int>) -> ArrayLongerThan0<Element> {
        let upperBound = self.array.index(self.array.startIndex, offsetBy: range.upperBound)
        let lowerBound = self.array.index(self.array.startIndex, offsetBy: range.lowerBound)

        return ArrayLongerThan0<Element>(self.array[lowerBound..<upperBound])
    }


    public mutating func insert(_ newElement: Element, at i: Int) {
        var newArray = Array(self.array)
        newArray.insert(newElement, at: i)
        self = PrefixedArrayEnd<Element>(newArray)
    }


    public mutating func insert<C: Collection>(contentsOf newElements: C, at i: Int) where C.Element == Element {
        var newArray = Array(self.array)
        newArray.insert(contentsOf: newElements, at: i)
        self = PrefixedArrayEnd<Element>(newArray)
    }


    public mutating func insert(contentsOf newElements: ArrayLongerThan0<Element>, at i: Int) {
        self.insert(contentsOf: newElements.relaxed(), at: i)
    }
    public mutating func insert(contentsOf newElements: ArrayLongerThan1<Element>, at i: Int) {
        self.insert(contentsOf: newElements.relaxed(), at: i)
    }
    public mutating func insert(contentsOf newElements: ArrayLongerThan2<Element>, at i: Int) {
        self.insert(contentsOf: newElements.relaxed(), at: i)
    }


    public mutating func append(_ newElement: Element) {
        var newArray = Array(self.array)
        newArray.append(newElement)
        self = PrefixedArrayEnd<Element>(newArray)
    }


    public mutating func append<S: Sequence>(
        contentsOf newElements: S
    ) where S.Element == Element {
        var newArray = Array(self.array)
        newArray.append(contentsOf: newElements)
        self = PrefixedArrayEnd<Element>(newArray)
    }


    public mutating func append(contentsOf newElements: ArrayLongerThan0<Element>) {
        self.append(contentsOf: newElements.relaxed())
    }
    public mutating func append(contentsOf newElements: ArrayLongerThan1<Element>) {
        self.append(contentsOf: newElements.relaxed())
    }
    public mutating func append(contentsOf newElements: ArrayLongerThan2<Element>) {
        self.append(contentsOf: newElements.relaxed())
    }


    public func dropFirst() -> PrefixedArrayEnd<Element>? {
        guard !self.array.isEmpty else {
            return nil
        }

        return PrefixedArrayEnd(self.array.dropFirst())
    }


    public func dropLast() -> AnyBidirectionalCollection<Element>? {
        guard !self.array.isEmpty else {
            return nil
        }

        return self.array.dropLast()
    }


    public func map<T>(_ f: (Element) throws -> T) rethrows -> PrefixedArrayEnd<T> {
        return PrefixedArrayEnd<T>(try self.array.map(f))
    }


    public func compactMap<T>(_ f: (Element) throws -> T?) rethrows -> PrefixedArrayEnd<T> {
        return PrefixedArrayEnd<T>(try self.array.compactMap(f))
    }


    public func flatMap<T, S: Sequence>(_ f: (Element) throws -> S) rethrows -> PrefixedArrayEnd<T> where S.Element == T {
        return PrefixedArrayEnd<T>(try self.array.flatMap(f))
    }


    public func enumerated() -> PrefixedArrayEnd<(Int, Element)> {
        return PrefixedArrayEnd<(Int, Element)>(Array(self.array.enumerated()))
    }


    public func flatMap<T>(_ f: (Element) throws -> ArrayLongerThan0<T>) rethrows -> PrefixedArrayEnd<T> {
        return try self.flatMap { try f($0).relaxed() }
    }
    public func flatMap<T>(_ f: (Element) throws -> ArrayLongerThan1<T>) rethrows -> PrefixedArrayEnd<T> {
        return try self.flatMap { try f($0).relaxed() }
    }
    public func flatMap<T>(_ f: (Element) throws -> ArrayLongerThan2<T>) rethrows -> PrefixedArrayEnd<T> {
        return try self.flatMap { try f($0).relaxed() }
    }


    public func filter(_ f: (Element) throws -> Bool) rethrows -> PrefixedArrayEnd<Element> {
        return PrefixedArrayEnd<Element>(try self.array.filter(f))
    }


    public func relaxed() -> AnyBidirectionalCollection<Element> {
        return self.array
    }


    public func sequence() -> ArrayLongerThan0Sequence<Element> {
        return self
    }
}



extension PrefixedArrayEnd: Equatable where Element: Equatable {
    public static func ==(lhs: PrefixedArrayEnd<Element>, rhs: PrefixedArrayEnd<Element>) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs.array, rhs.array).allSatisfy { $0.0 == $0.1 }
    }
}



extension PrefixedArrayEnd: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.array.forEach { hasher.combine($0) }
    }
}



extension PrefixedArrayEnd: Sequence {
    public typealias Iterator = PrefixedArrayEndIterator<Element>


    public func makeIterator() -> PrefixedArrayEndIterator<Element> {
        return Iterator(self)
    }
}



public struct PrefixedArrayEndIterator<Element>: IteratorProtocol {
    private let array: PrefixedArrayEnd<Element>
    private var position: Int


    public init(_ array: PrefixedArrayEnd<Element>) {
        self.init(array, at: array.startIndex)
    }


    public init(_ array: PrefixedArrayEnd<Element>, at position: Int) {
        self.array = array
        self.position = position
    }


    public mutating func next() -> Element? {
        guard self.position <= self.array.endIndex else {
            return nil
        }

        let result = self.array[self.position]
        self.position += 1
        return result
    }
}



public typealias ArrayLongerThan0<Element> = PrefixedArrayEnd<Element>
public typealias ArrayLongerThan1<Element> = PrefixedArray<Element, ArrayLongerThan0<Element>>
public typealias ArrayLongerThan2<Element> = PrefixedArray<Element, ArrayLongerThan1<Element>>



extension PrefixedArray where RestElements == ArrayLongerThan0<Element> {
    // ArrayLongerThan1
    public var count: Int {
        return self.rest.count + 1
    }


    // ArrayLongerThan1
    public var last: Element {
        guard let last = self.rest.last else {
            return self.first
        }
        return last
    }


    // ArrayLongerThan1
    public init?<C: BidirectionalCollection>(_ array: C) where C.Element == Element {
        guard let first = array.first else {
            return nil
        }

        let restEnoughLength = PrefixedArrayEnd<Element>(array.dropFirst())

        self.init(prefix: first, restEnoughLength)
    }


    // ArrayLongerThan1
    public init?(_ array: ArrayLongerThan0<Element>) {
        guard let (first, rest) = array.firstAndRest else {
            return nil
        }

        let restEnoughLength = ArrayLongerThan0<Element>(rest)

        self.init(prefix: first, restEnoughLength)
    }


    // ArrayLongerThan1
    public init(_ array: ArrayLongerThan1<Element>) {
        self = array
    }
    // ArrayLongerThan1
    public init(_ array: ArrayLongerThan2<Element>) {
        self.init(prefix: array.first, array.rest.relaxed())
    }


    // ArrayLongerThan1
    public init(prefix: Element, _ array: ArrayLongerThan1<Element>) {
        self.init(prefix: prefix, array.relaxed())
    }


    // ArrayLongerThan1
    public init(suffix: Element, _ array: ArrayLongerThan1<Element>) {
        self.init(suffix: suffix, array.relaxed())
    }
    // ArrayLongerThan1
    public init(prefix: Element, _ array: ArrayLongerThan2<Element>) {
        self.init(prefix: prefix, array.relaxed())
    }


    // ArrayLongerThan1
    public init(suffix: Element, _ array: ArrayLongerThan2<Element>) {
        self.init(suffix: suffix, array.relaxed())
    }


    // ArrayLongerThan1
    public init(suffix: Element, _ array: ArrayLongerThan0<Element>) {
        guard let (first, rest) = array.firstAndRest else {
            self.init(prefix: suffix, PrefixedArrayEnd<Element>([]))
            return
        }

        self.init(
            prefix: first,
            ArrayLongerThan0<Element>(suffix: suffix, rest)
        )
    }


    // ArrayLongerThan1
    public init<C: BidirectionalCollection>(prefix: Element, _ array: C) where C.Element == Element {
        self.init(prefix: prefix, PrefixedArrayEnd<Element>(array))
    }


    // ArrayLongerThan1
    public init<C: BidirectionalCollection>(suffix: Element, _ array: C) where C.Element == Element {
        guard let first = array.first else {
            self.init(prefix: suffix, PrefixedArrayEnd<Element>([]))
            return
        }

        var newRest = Array(array.dropFirst())
        newRest.append(suffix)

        self.init(prefix: first, PrefixedArrayEnd<Element>(newRest))
    }


    // ArrayLongerThan1
    public subscript(index: Int) -> Element {
        guard index != 0 else {
            return self.first
        }
        return self.rest[index - 1]
    }


    // ArrayLongerThan1
    public subscript(range: Range<Int>) -> ArrayLongerThan0<Element> {
        return self.relaxed()[range]
    }


    // ArrayLongerThan1
    public mutating func insert(_ newElement: Element, at i: Int) {
        guard i > 0 else {
            self = ArrayLongerThan1<Element>(
                prefix: newElement,
                self.relaxed()
            )
            return
        }

        var newRest = self.rest
        newRest.insert(newElement, at: i - 1)

        self = ArrayLongerThan1<Element>(
            prefix: self.prefix,
            newRest
        )
    }


    // ArrayLongerThan1
    public mutating func insert(contentsOf newElements: ArrayLongerThan0<Element>, at i: Int) {
        // TODO: Check the standard behavior to handle negative values.
        guard i > 0 else {
            guard let (first, rest) = newElements.firstAndRest else { return }

            self = ArrayLongerThan1<Element>(
                prefix: first,
                rest + ArrayLongerThan1(self) // NOTE: Avoid to use exceeded length types.
            )
            return
        }

        var newRest = self.rest
        newRest.insert(contentsOf: newElements, at: i - 1)

        self = ArrayLongerThan1<Element>(
            prefix: self.prefix,
            newRest
        )
    }
    // ArrayLongerThan1
    public mutating func insert(contentsOf newElements: ArrayLongerThan1<Element>, at i: Int) {
        // TODO: Check the standard behavior to handle negative values.
        guard i > 0 else {
            let (first, rest) = newElements.firstAndRest

            self = ArrayLongerThan1<Element>(
                prefix: first,
                rest + ArrayLongerThan0(self) // NOTE: Avoid to use exceeded length types.
            )
            return
        }

        var newRest = self.rest
        newRest.insert(contentsOf: newElements, at: i - 1)

        self = ArrayLongerThan1<Element>(
            prefix: self.prefix,
            newRest
        )
    }
    // ArrayLongerThan1
    public mutating func insert(contentsOf newElements: ArrayLongerThan2<Element>, at i: Int) {
        // TODO: Check the standard behavior to handle negative values.
        guard i > 0 else {
            let (first, rest) = newElements.firstAndRest

            self = ArrayLongerThan1<Element>(
                prefix: first,
                rest + ArrayLongerThan0(self) // NOTE: Avoid to use exceeded length types.
            )
            return
        }

        var newRest = self.rest
        newRest.insert(contentsOf: newElements, at: i - 1)

        self = ArrayLongerThan1<Element>(
            prefix: self.prefix,
            newRest
        )
    }


    // ArrayLongerThan1
    public mutating func append(_ newElement: Element) {
        var newRest = self.rest
        newRest.append(newElement)
        self = ArrayLongerThan1<Element>(
            prefix: self.prefix,
            newRest
        )
    }


    // ArrayLongerThan1
    public mutating func append(contentsOf newElements: ArrayLongerThan0<Element>) {
        var newRest = self.rest
        newRest.append(contentsOf: newElements)
        self = ArrayLongerThan1<Element>(
            prefix: self.prefix,
            newRest
        )
    }
    // ArrayLongerThan1
    public mutating func append(contentsOf newElements: ArrayLongerThan1<Element>) {
        var newRest = self.rest
        newRest.append(contentsOf: newElements)
        self = ArrayLongerThan1<Element>(
            prefix: self.prefix,
            newRest
        )
    }
    // ArrayLongerThan1
    public mutating func append(contentsOf newElements: ArrayLongerThan2<Element>) {
        var newRest = self.rest
        newRest.append(contentsOf: newElements)
        self = ArrayLongerThan1<Element>(
            prefix: self.prefix,
            newRest
        )
    }


    // ArrayLongerThan1
    public func dropLast() -> PrefixedArrayEnd<Element> {
        guard let rest = self.rest.dropLast() else {
            return PrefixedArrayEnd([])
        }

        return PrefixedArrayEnd(
            prefix: self.first,
            rest
        )
    }


    // ArrayLongerThan1
    public func map<T>(_ f: (Element) throws -> T) rethrows -> ArrayLongerThan1<T> {
        return ArrayLongerThan1<T>(
            prefix: try f(self.first),
            try self.rest.map(f)
        )
    }


    // ArrayLongerThan1
    public func compactMap<T>(_ f: (Element) throws -> T?) rethrows -> PrefixedArrayEnd<T> {
        return try self.relaxed().compactMap(f)
    }


    // ArrayLongerThan1
    public func filter(_ f: (Element) throws -> Bool) rethrows -> PrefixedArrayEnd<Element> {
        return try self.relaxed().filter(f)
    }


    // ArrayLongerThan1
    public func flatMap<T, S: Sequence>(_ f: (Element) throws -> S) rethrows -> PrefixedArrayEnd<T> where S.Element == T {
        return try self.relaxed().flatMap(f)
    }


    // ArrayLongerThan1
    public func enumerated() -> ArrayLongerThan1<(Int, Element)> {
        return ArrayLongerThan1<(Int, Element)>(
            prefix: (0, self.first),
            self.rest.enumerated().map { ($0.0 + 1, $0.1) }
        )
    }


    // ArrayLongerThan1
    public func relaxed() -> ArrayLongerThan0<Element> {
        return ArrayLongerThan0<Element>(
            prefix: self.prefix,
            self.rest.relaxed()
        )
    }
}
extension PrefixedArray where RestElements == ArrayLongerThan1<Element> {
    // ArrayLongerThan2
    public var count: Int {
        return self.rest.count + 1
    }


    // ArrayLongerThan2
    public var last: Element {
        return self.rest.last
    }


    // ArrayLongerThan2
    public init?<C: BidirectionalCollection>(_ array: C) where C.Element == Element {
        guard let first = array.first else {
            return nil
        }

        guard let restEnoughLength = ArrayLongerThan1<Element>(array.dropFirst()) else { return nil }

        self.init(prefix: first, restEnoughLength)
    }


    // ArrayLongerThan2
    public init?(_ array: ArrayLongerThan0<Element>) {
        guard let (first, rest) = array.firstAndRest else {
            return nil
        }

        guard let restEnoughLength = ArrayLongerThan1<Element>(rest) else {
            return nil
        }

        self.init(prefix: first, restEnoughLength)
    }


    // ArrayLongerThan2
    public init?(_ array: ArrayLongerThan1<Element>) {
        guard let restEnoughLength = ArrayLongerThan1<Element>(array.rest) else {
            return nil
        }

        self.init(prefix: array.first, restEnoughLength)
    }
    // ArrayLongerThan2
    public init(_ array: ArrayLongerThan2<Element>) {
        self = array
    }


    // ArrayLongerThan2
    public init(prefix: Element, _ array: ArrayLongerThan2<Element>) {
        self.init(prefix: prefix, array.relaxed())
    }


    // ArrayLongerThan2
    public init(suffix: Element, _ array: ArrayLongerThan2<Element>) {
        self.init(suffix: suffix, array.relaxed())
    }


    public init(suffix: Element, _ array: ArrayLongerThan1<Element>) {
        self.init(
            prefix: array.first,
            ArrayLongerThan1<Element>(suffix: suffix, array.rest)
        )
    }


    // ArrayLongerThan2
    public init?<C: BidirectionalCollection>(prefix: Element, _ array: C) where C.Element == Element {
        guard let rest = ArrayLongerThan1<Element>(array) else {
            return nil
        }

        self.init(prefix: prefix, rest)
    }


    // ArrayLongerThan2
    public init?<C: BidirectionalCollection>(suffix: Element, _ array: C) where C.Element == Element {
        guard let head = ArrayLongerThan1<Element>(array) else {
            return nil
        }

        self.init(suffix: suffix, head)
    }


    // ArrayLongerThan2
    public subscript(index: Int) -> Element {
        guard index != 0 else {
            return self.first
        }
        return self.rest[index - 1]
    }


    // ArrayLongerThan2
    public subscript(range: Range<Int>) -> ArrayLongerThan0<Element> {
        return self.relaxed()[range]
    }


    // ArrayLongerThan2
    public mutating func insert(_ newElement: Element, at i: Int) {
        guard i > 0 else {
            self = ArrayLongerThan2<Element>(
                prefix: newElement,
                self.relaxed()
            )
            return
        }

        var newRest = self.rest
        newRest.insert(newElement, at: i - 1)

        self = ArrayLongerThan2<Element>(
            prefix: self.prefix,
            newRest
        )
    }


    // ArrayLongerThan2
    public mutating func insert(contentsOf newElements: ArrayLongerThan0<Element>, at i: Int) {
        // TODO: Check the standard behavior to handle negative values.
        guard i > 0 else {
            guard let (first, rest) = newElements.firstAndRest else { return }

            self = ArrayLongerThan2<Element>(
                prefix: first,
                rest + ArrayLongerThan2(self) // NOTE: Avoid to use exceeded length types.
            )
            return
        }

        var newRest = self.rest
        newRest.insert(contentsOf: newElements, at: i - 1)

        self = ArrayLongerThan2<Element>(
            prefix: self.prefix,
            newRest
        )
    }
    // ArrayLongerThan2
    public mutating func insert(contentsOf newElements: ArrayLongerThan1<Element>, at i: Int) {
        // TODO: Check the standard behavior to handle negative values.
        guard i > 0 else {
            let (first, rest) = newElements.firstAndRest

            self = ArrayLongerThan2<Element>(
                prefix: first,
                rest + ArrayLongerThan1(self) // NOTE: Avoid to use exceeded length types.
            )
            return
        }

        var newRest = self.rest
        newRest.insert(contentsOf: newElements, at: i - 1)

        self = ArrayLongerThan2<Element>(
            prefix: self.prefix,
            newRest
        )
    }
    // ArrayLongerThan2
    public mutating func insert(contentsOf newElements: ArrayLongerThan2<Element>, at i: Int) {
        // TODO: Check the standard behavior to handle negative values.
        guard i > 0 else {
            let (first, rest) = newElements.firstAndRest

            self = ArrayLongerThan2<Element>(
                prefix: first,
                rest + ArrayLongerThan0(self) // NOTE: Avoid to use exceeded length types.
            )
            return
        }

        var newRest = self.rest
        newRest.insert(contentsOf: newElements, at: i - 1)

        self = ArrayLongerThan2<Element>(
            prefix: self.prefix,
            newRest
        )
    }


    // ArrayLongerThan2
    public mutating func append(_ newElement: Element) {
        var newRest = self.rest
        newRest.append(newElement)
        self = ArrayLongerThan2<Element>(
            prefix: self.prefix,
            newRest
        )
    }


    // ArrayLongerThan2
    public mutating func append(contentsOf newElements: ArrayLongerThan0<Element>) {
        var newRest = self.rest
        newRest.append(contentsOf: newElements)
        self = ArrayLongerThan2<Element>(
            prefix: self.prefix,
            newRest
        )
    }
    // ArrayLongerThan2
    public mutating func append(contentsOf newElements: ArrayLongerThan1<Element>) {
        var newRest = self.rest
        newRest.append(contentsOf: newElements)
        self = ArrayLongerThan2<Element>(
            prefix: self.prefix,
            newRest
        )
    }
    // ArrayLongerThan2
    public mutating func append(contentsOf newElements: ArrayLongerThan2<Element>) {
        var newRest = self.rest
        newRest.append(contentsOf: newElements)
        self = ArrayLongerThan2<Element>(
            prefix: self.prefix,
            newRest
        )
    }


    // ArrayLongerThan2
    public func dropLast() -> ArrayLongerThan1<Element> {
        return ArrayLongerThan1<Element>(
            prefix: self.first,
            rest.dropLast()
        )
    }


    // ArrayLongerThan2
    public func map<T>(_ f: (Element) throws -> T) rethrows -> ArrayLongerThan2<T> {
        return ArrayLongerThan2<T>(
            prefix: try f(self.first),
            try self.rest.map(f)
        )
    }


    // ArrayLongerThan2
    public func compactMap<T>(_ f: (Element) throws -> T?) rethrows -> PrefixedArrayEnd<T> {
        return try self.relaxed().compactMap(f)
    }


    // ArrayLongerThan2
    public func filter(_ f: (Element) throws -> Bool) rethrows -> PrefixedArrayEnd<Element> {
        return try self.relaxed().filter(f)
    }


    // ArrayLongerThan2
    public func flatMap<T, S: Sequence>(_ f: (Element) throws -> S) rethrows -> PrefixedArrayEnd<T> where S.Element == T {
        return try self.relaxed().flatMap(f)
    }


    // ArrayLongerThan2
    public func enumerated() -> ArrayLongerThan2<(Int, Element)> {
        return ArrayLongerThan2<(Int, Element)>(
            prefix: (0, self.first),
            self.rest.enumerated().map { ($0.0 + 1, $0.1) }
        )
    }


    // ArrayLongerThan2
    public func relaxed() -> ArrayLongerThan1<Element> {
        return ArrayLongerThan1<Element>(
            prefix: self.prefix,
            self.rest.relaxed()
        )
    }
}


public func +<Element>(lhs: ArrayLongerThan0<Element>, rhs: PrefixedArrayEnd<Element>) -> ArrayLongerThan0<Element> {
    var result = lhs
    result.append(contentsOf: rhs)
    return result
}
public func +<Element>(lhs: ArrayLongerThan0<Element>, rhs: ArrayLongerThan1<Element>) -> ArrayLongerThan1<Element> {
    return ArrayLongerThan1(suffix: rhs.last, lhs + rhs.dropLast())
}
public func +<Element>(lhs: ArrayLongerThan0<Element>, rhs: ArrayLongerThan2<Element>) -> ArrayLongerThan2<Element> {
    return ArrayLongerThan2(suffix: rhs.last, lhs + rhs.dropLast())
}
public func +<Element>(lhs: ArrayLongerThan1<Element>, rhs: PrefixedArrayEnd<Element>) -> ArrayLongerThan1<Element> {
    var result = lhs
    result.append(contentsOf: rhs)
    return result
}
public func +<Element>(lhs: ArrayLongerThan1<Element>, rhs: ArrayLongerThan1<Element>) -> ArrayLongerThan2<Element> {
    return ArrayLongerThan2(suffix: rhs.last, lhs + rhs.dropLast())
}
public func +<Element>(lhs: ArrayLongerThan2<Element>, rhs: PrefixedArrayEnd<Element>) -> ArrayLongerThan2<Element> {
    var result = lhs
    result.append(contentsOf: rhs)
    return result
}



extension PrefixedArrayEnd where Element: Sequence {
    public func joined() -> PrefixedArrayEnd<Element.Element> {
        return PrefixedArrayEnd<Element.Element>(Array(self.array.joined()))
    }
}



extension PrefixedArray where Element: Sequence, RestElements == ArrayLongerThan0<Element> {
    public func joined() -> PrefixedArrayEnd<Element.Element> {
        return self.relaxed().joined()
    }
}
extension PrefixedArray where Element: Sequence, RestElements == ArrayLongerThan1<Element> {
    public func joined() -> PrefixedArrayEnd<Element.Element> {
        return self.relaxed().joined()
    }
}



extension PrefixedArrayEnd where Element == String {
    public func joined(separator: String) -> String {
        return self.array.joined(separator: separator)
    }
}



extension PrefixedArray where Element == String, RestElements == ArrayLongerThan0<String> {
    public func joined(separator: String) -> String {
        return self.relaxed().joined(separator: separator)
    }
}
extension PrefixedArray where Element == String, RestElements == ArrayLongerThan1<String> {
    public func joined(separator: String) -> String {
        return self.relaxed().joined(separator: separator)
    }
}


func zip<A, B>(_ a: ArrayLongerThan0<A>, _ b: ArrayLongerThan0<B>) -> ArrayLongerThan0<(A, B)> {
    return ArrayLongerThan0<(A, B)>(Array(zip(a.relaxed(), b.relaxed())))
}


func zip<A, B>(_ a: ArrayLongerThan1<A>, _ b: ArrayLongerThan1<B>) -> ArrayLongerThan1<(A, B)> {
    return ArrayLongerThan1<(A, B)>(
        prefix: (a.first, b.first),
        zip(a.rest, b.rest)
    )
}
func zip<A, B>(_ a: ArrayLongerThan2<A>, _ b: ArrayLongerThan2<B>) -> ArrayLongerThan2<(A, B)> {
    return ArrayLongerThan2<(A, B)>(
        prefix: (a.first, b.first),
        zip(a.rest, b.rest)
    )
}



func zip<A: Sequence, B: Sequence, C: Sequence>(_ a: A, _ b: B, _ c: C) -> [(A.Element, B.Element, C.Element)] {
    return zip(zip(a, b), c).map { ($0.0.0, $0.0.1, $0.1) }
}



func zip<A, B, C>(_ a: ArrayLongerThan0<A>, _ b: ArrayLongerThan0<B>, _ c: ArrayLongerThan0<C>) -> ArrayLongerThan0<(A, B, C)> {
    return ArrayLongerThan0<(A, B, C)>(Array(zip(a.relaxed(), b.relaxed(), c.relaxed())))
}



func zip<A, B, C>(_ a: ArrayLongerThan1<A>, _ b: ArrayLongerThan1<B>, _ c: ArrayLongerThan1<C>) -> ArrayLongerThan1<(A, B, C)> {
    return ArrayLongerThan1<(A, B, C)>(
        prefix: (a.first, b.first, c.first),
        zip(a.rest, b.rest, c.rest)
    )
}
func zip<A, B, C>(_ a: ArrayLongerThan2<A>, _ b: ArrayLongerThan2<B>, _ c: ArrayLongerThan2<C>) -> ArrayLongerThan2<(A, B, C)> {
    return ArrayLongerThan2<(A, B, C)>(
        prefix: (a.first, b.first, c.first),
        zip(a.rest, b.rest, c.rest)
    )
}
