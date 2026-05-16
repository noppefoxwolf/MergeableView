import SwiftUI

extension View {
    @available(iOS 26.0, *)
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
                    guard let indexes = adjacentMergeIndexes(
                        sourceID: sourceID,
                        destinationID: destinationID
                    ) else {
                        return
                    }

                    action(indexes.source, indexes.destination)
                },
                candidateAllows: { sourceID, destinationID in
                    adjacentMergeIndexes(sourceID: sourceID, destinationID: destinationID) != nil
                }
            )
        )
    }

    private func adjacentMergeIndexes(
        sourceID: ID,
        destinationID: ID
    ) -> (source: Int, destination: Int)? {
        guard
            let sourceIndex = data.firstIndex(where: { $0.id == sourceID }),
            let destinationIndex = data.firstIndex(where: { $0.id == destinationID }),
            abs(data.distance(from: sourceIndex, to: destinationIndex)) == 1
        else {
            return nil
        }

        return (
            source: data.distance(from: data.startIndex, to: sourceIndex),
            destination: data.distance(from: data.startIndex, to: destinationIndex)
        )
    }
}
