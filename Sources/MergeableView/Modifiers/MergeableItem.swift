import SwiftUI

@available(iOS 26.0, *)
struct MergeableItem<ID: Hashable & Sendable>: ViewModifier {
    @Environment(\.mergeableNamespace)
    private var namespace

    @Environment(\.mergeDragEnded)
    private var mergeDragEnded

    @Environment(\.mergeAction)
    private var mergeAction

    @Environment(\.mergeCandidateAllows)
    private var mergeCandidateAllows

    @Environment(\.mergeableItemFrameUpdated)
    private var mergeableItemFrameUpdated

    let id: ID

    init(id: ID) {
        self.id = id
    }

    func body(content: Content) -> some View {
        if let namespace {
            itemContent(content)
                .glassEffectID(id, in: namespace)
                .glassEffectTransition(.matchedGeometry)
        } else {
            itemContent(content)
        }
    }

    private func itemContent(_ content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named(MergeableItemLayout.coordinateSpace))
            } action: { frame in
                mergeableItemFrameUpdated?(.changed(MergeableItemID(id), frame))
            }
            .highPriorityGesture(mergeGesture)
            .onDisappear {
                mergeableItemFrameUpdated?(.removed(MergeableItemID(id)))
            }
    }

    private var mergeGesture: some Gesture {
        DragGesture(coordinateSpace: .named(MergeableItemLayout.coordinateSpace))
            .onEnded { value in
                mergeDragEnded?(.init(
                    startLocation: value.startLocation,
                    currentLocation: value.location,
                    action: mergeAction,
                    candidateAllows: mergeCandidateAllows
                )
                )
            }
    }
}
