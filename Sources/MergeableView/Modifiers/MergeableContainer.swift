import SwiftUI

@available(iOS 26.0, *)
public struct MergeableContainer<Content: View>: View {
    @State
    private var itemFrames: [MergeableItemID: CGRect] = [:]
    @State
    private var dragSelection = MergeDragSelection<MergeableItemID>()

    @Namespace
    private var namespace

    let content: () -> Content

    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        GlassEffectContainer(content: content)
            .environment(\.mergeableNamespace, namespace)
            .environment(\.mergeDragEnded, handleDragEnded)
            .environment(\.mergeableItemFrameUpdated, updateItemFrame)
            .coordinateSpace(name: MergeableItemLayout.coordinateSpace)
    }

    private func handleDragEnded(_ context: MergeDragContext) {
        updateDragSelection(
            startLocation: context.startLocation,
            currentLocation: context.currentLocation,
            candidateAllows: context.candidateAllows
        )
        mergeSelectedItems(perform: context.action)
    }

    private func updateItemFrame(_ update: MergeableItemFrameUpdate) {
        switch update {
        case let .changed(id, frame):
            itemFrames[id] = frame
        case let .removed(id):
            itemFrames.removeValue(forKey: id)
        }
    }

    private func updateDragSelection(
        startLocation: CGPoint,
        currentLocation: CGPoint,
        candidateAllows: EnvironmentValues.MergeCandidateAllows?
    ) {
        let resolver = MergeTargetResolver(itemFrames: itemFrames)
        dragSelection.startItemID = resolver.itemID(at: startLocation)
        dragSelection.currentItemID = resolver.nearestTarget(
            from: startLocation,
            toward: currentLocation,
            candidateAllows: { sourceID, destinationID in
                candidateAllows?(sourceID, destinationID) ?? true
            }
        )?.destinationID
    }

    private func mergeSelectedItems(
        perform action: (@MainActor (MergeableItemID, MergeableItemID) -> Void)?
    ) {
        guard
            let sourceID = dragSelection.startItemID,
            let destinationID = dragSelection.currentItemID
        else {
            return
        }

        action?(sourceID, destinationID)
        dragSelection = MergeDragSelection<MergeableItemID>()
    }
}
