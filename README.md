# MergeableView

MergeableView is a SwiftUI package for building Liquid Glass views that can be merged by dragging one item toward another.

The package provides a small set of primitives:

- `MergableContainer` creates a shared glass effect and merge coordinate space.
- `.mergeableItem(id:)` marks each view as a merge target.
- `.onMerge` on `ForEach` reports the source and destination indices when a merge gesture completes.

## Requirements

- iOS 26.0+
- Swift 6
- Swift Package Manager

## Installation

Add this package to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/noppefoxwolf/MergeableView.git", branch: "main")
]
```

Then add `MergeableView` to your target dependencies:

```swift
.product(name: "MergeableView", package: "MergeableView")
```

## Usage

Import the package and wrap mergeable views in `MergableContainer`.

```swift
import MergeableView
import SwiftUI

struct ContentView: View {
    @State private var tokens = [
        Token(text: "Liquid"),
        Token(text: "Glass"),
        Token(text: "Effect")
    ]

    var body: some View {
        MergableContainer {
            VStack(alignment: .leading) {
                ForEach(tokens) { token in
                    Text(token.text)
                        .bold()
                        .padding()
                        .glassEffect(.regular.interactive())
                        .mergeableItem(id: token.id)
                }
                .onMerge { sourceIndex, destinationIndex in
                    merge(sourceIndex, with: destinationIndex)
                }
            }
        }
    }

    private func merge(_ sourceIndex: Int, with destinationIndex: Int) {
        guard
            sourceIndex != destinationIndex,
            tokens.indices.contains(sourceIndex),
            tokens.indices.contains(destinationIndex)
        else {
            return
        }

        let orderedIndices = [sourceIndex, destinationIndex].sorted()
        let source = tokens[orderedIndices[0]]
        let destination = tokens[orderedIndices[1]]
        let mergedToken = Token(text: "\(source.text) \(destination.text)")

        tokens.remove(at: orderedIndices[1])
        tokens.remove(at: orderedIndices[0])
        tokens.insert(mergedToken, at: orderedIndices[0])
    }
}

struct Token: Identifiable, Hashable {
    let id = UUID()
    var text: String
}
```

Drag from one mergeable item toward another item to trigger `.onMerge`. The callback receives the source index and destination index from the `ForEach` data.

## Example

An example app is included in `Example.swiftpm`.

Open `Example.swiftpm` in Xcode and run the `Example` app on an iOS 26 simulator or device.

## License

MergeableView is available under the MIT License. See [LICENSE](LICENSE) for details.
