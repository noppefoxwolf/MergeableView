struct MergeableItemID: Hashable {
    private let value: AnyHashable

    init<ID: Hashable & Sendable>(_ id: ID) {
        value = AnyHashable(id)
    }

    func cast<ID: Hashable>(to type: ID.Type = ID.self) -> ID? {
        value.base as? ID
    }
}
