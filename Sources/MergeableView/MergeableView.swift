import SwiftUI

extension View {
    public func mergeableItem<ID: Hashable & Sendable>(id: ID) -> some View {
        modifier(MergeableItem(id: id))
    }
}

extension ForEach
where
    Data: RandomAccessCollection,
    Data.Element: Identifiable,
    ID == Data.Element.ID,
    ID: Sendable,
    Content: View
{
    @MainActor
    public func onMerge(perform action: @escaping @MainActor (Int, Int) -> Void) -> some View {
        modifier(
            OnMerge<ID>(
                action: { sourceID, destinationID in
                    guard
                        let sourceIndex = data.firstIndex(where: { $0.id == sourceID }),
                        let destinationIndex = data.firstIndex(where: { $0.id == destinationID }),
                        abs(data.distance(from: sourceIndex, to: destinationIndex)) == 1
                    else {
                        return
                    }

                    action(
                        data.distance(from: data.startIndex, to: sourceIndex),
                        data.distance(from: data.startIndex, to: destinationIndex)
                    )
                },
                candidateAllows: { sourceID, destinationID in
                    guard
                        let sourceIndex = data.firstIndex(where: { $0.id == sourceID }),
                        let destinationIndex = data.firstIndex(where: { $0.id == destinationID })
                    else {
                        return false
                    }

                    return abs(data.distance(from: sourceIndex, to: destinationIndex)) == 1
                }
            )
        )
    }
}
