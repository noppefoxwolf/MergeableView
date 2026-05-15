import CoreGraphics
import Testing

@testable import MergeableView

@Test func resolverReturnsItemContainingLocation() {
    let resolver = MergeTargetResolver(
        itemFrames: [
            "first": CGRect(x: 0, y: 0, width: 40, height: 40),
            "second": CGRect(x: 60, y: 0, width: 40, height: 40)
        ]
    )

    #expect(resolver.itemID(at: CGPoint(x: 20, y: 20)) == "first")
    #expect(resolver.itemID(at: CGPoint(x: 80, y: 20)) == "second")
    #expect(resolver.itemID(at: CGPoint(x: 50, y: 20)) == nil)
}

@Test func resolverReturnsNearestIntersectedItemInDragDirection() {
    let resolver = MergeTargetResolver(
        itemFrames: [
            "source": CGRect(x: 0, y: 0, width: 40, height: 40),
            "near": CGRect(x: 60, y: 0, width: 40, height: 40),
            "far": CGRect(x: 120, y: 0, width: 40, height: 40),
            "behind": CGRect(x: -60, y: 0, width: 40, height: 40)
        ]
    )

    let nearestID = resolver.nearestItemID(
        from: CGPoint(x: 20, y: 20),
        toward: CGPoint(x: 150, y: 20)
    )

    #expect(nearestID == "near")
}

@Test func resolverHonorsCandidateFilter() {
    let resolver = MergeTargetResolver(
        itemFrames: [
            "source": CGRect(x: 0, y: 0, width: 40, height: 40),
            "blocked": CGRect(x: 60, y: 0, width: 40, height: 40),
            "allowed": CGRect(x: 120, y: 0, width: 40, height: 40)
        ]
    )

    let nearestID = resolver.nearestItemID(
        from: CGPoint(x: 20, y: 20),
        toward: CGPoint(x: 150, y: 20),
        candidateAllows: { _, destinationID in destinationID != "blocked" }
    )

    #expect(nearestID == "allowed")
}

@Test func resolverIgnoresCandidatesOutsideDragDirection() {
    let resolver = MergeTargetResolver(
        itemFrames: [
            "source": CGRect(x: 0, y: 0, width: 40, height: 40),
            "behind": CGRect(x: -60, y: 0, width: 40, height: 40)
        ]
    )

    let nearestID = resolver.nearestItemID(
        from: CGPoint(x: 20, y: 20),
        toward: CGPoint(x: 80, y: 20)
    )

    #expect(nearestID == nil)
}

@Test func lineSegmentIntersectionIncludesCrossingAndTouchingSegments() {
    #expect(
        MergeLineSegment.intersects(
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 0, y: 10),
            CGPoint(x: 10, y: 0)
        )
    )
    #expect(
        MergeLineSegment.intersects(
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 20, y: 0)
        )
    )
}

@Test func lineSegmentIntersectionRejectsSeparatedSegments() {
    #expect(
        MergeLineSegment.intersects(
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 0, y: 10),
            CGPoint(x: 10, y: 10)
        ) == false
    )
}
