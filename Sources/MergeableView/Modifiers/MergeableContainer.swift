import SwiftUI

public struct MergeableContainer<Content: View>: View {
    @State
    private var itemFrames: [AnyHashable: CGRect] = [:]
    @State
    private var dragSelection = MergeDragSelection<AnyHashable>()

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
            .environment(\.mergeableItemFrameChanged, updateItemFrame)
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

    private func updateItemFrame(id: AnyHashable, frame: CGRect?) {
        if let frame {
            itemFrames[id] = frame
        } else {
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
        dragSelection.currentItemID = resolver.nearestItemID(
            from: startLocation,
            toward: currentLocation,
            candidateAllows: { sourceID, destinationID in
                candidateAllows?(sourceID, destinationID) ?? true
            }
        )
    }

    private func mergeSelectedItems(
        perform action: (@MainActor @Sendable (AnyHashable, AnyHashable) -> Void)?
    ) {
        guard
            let sourceID = dragSelection.startItemID,
            let destinationID = dragSelection.currentItemID
        else {
            return
        }

        action?(sourceID, destinationID)
        dragSelection = MergeDragSelection<AnyHashable>()
    }
}
