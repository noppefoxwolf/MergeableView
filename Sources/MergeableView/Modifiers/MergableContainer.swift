import SwiftUI

public struct MergableContainer<Content: View>: View {
    
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
            .environment(\.mergeDragEnded) { startLocation, currentLocation, action in
                updateDragSelection(startLocation: startLocation, currentLocation: currentLocation)
                mergeSelectedItems(perform: action)
            }
            .environment(\.mergeableItemFrameChanged) { id, frame in
                itemFrames[id] = frame
            }
            .coordinateSpace(name: MergeableItemLayout.coordinateSpace)
    }
    
    private func updateDragSelection(startLocation: CGPoint, currentLocation: CGPoint) {
        dragSelection.startItemID = itemID(at: startLocation)
        dragSelection.currentItemID = nearestItemID(
            from: startLocation,
            toward: currentLocation
        )
    }

    private func itemID(at location: CGPoint) -> AnyHashable? {
        itemFrames
            .first { itemFrame in itemFrame.value.contains(location) }?
            .key
    }

    private func nearestItemID(from startLocation: CGPoint, toward currentLocation: CGPoint) -> AnyHashable? {
        guard
            let sourceID = itemID(at: startLocation),
            let sourceFrame = itemFrames[sourceID]
        else {
            return nil
        }

        let direction = CGVector(
            dx: currentLocation.x - startLocation.x,
            dy: currentLocation.y - startLocation.y
        )

        guard direction.length > 0 else {
            return nil
        }

        let sourceCenter = sourceFrame.center
        return itemFrames
            .filter { id, frame in
                guard id != sourceID else {
                    return false
                }

                let candidateDirection = CGVector(
                    dx: frame.center.x - sourceCenter.x,
                    dy: frame.center.y - sourceCenter.y
                )
                return direction.dot(candidateDirection) > 0
            }
            .min { lhs, rhs in
                sourceCenter.distance(to: lhs.value.center) < sourceCenter.distance(to: rhs.value.center)
            }?
            .key
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

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        hypot(x - point.x, y - point.y)
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

private extension CGVector {
    var length: CGFloat {
        hypot(dx, dy)
    }

    func dot(_ vector: CGVector) -> CGFloat {
        dx * vector.dx + dy * vector.dy
    }
}
