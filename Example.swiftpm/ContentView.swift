import MergeableView
import SwiftUI

struct ContentView: View {
    @State
    private var tokens = Token.initialTokens

    var body: some View {
        NavigationStack(root: {
            MergeableContainer {
                WrappingHStack(alignment: .leading) {
                    ForEach(tokens) { token in
                        Button(
                            action: {},
                            label: {
                                Label(token.text, systemImage: "plus")
                                    .bold()
                            }
                        )
                        .labelStyle(.titleAndIcon)
                        .buttonStyle(.glass)
                        .mergeableItem(id: token.id)
                    }
                    .onMerge { (sourceIndex: Int, destinationIndex: Int) in
                        tokens = tokens.merged(sourceIndex, with: destinationIndex) {
                            source,
                            destination in
                            Token(text: [source.text, destination.text].joined(separator: " "))
                        }
                    }
                }
            }
            .animation(.default, value: tokens)
            .padding()
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Reset", action: resetTokens)
                }
            }
        })
    }

    private func resetTokens() {
        tokens = Token.initialTokens
    }
}

struct Token: Identifiable, Hashable {
    let id = UUID()
    var text: String

    static var initialTokens: [Token] {
        [
            Token(text: "Liquid"),
            Token(text: "Glass"),
            Token(text: "Effect"),
            Token(text: "Token"),
        ]
    }
}

extension Array where Element == Token {
    func merged(
        _ sourceIndex: Int,
        with destinationIndex: Int,
        merge: (Token, Token) -> Token
    ) -> [Token] {
        guard
            sourceIndex != destinationIndex,
            indices.contains(sourceIndex),
            indices.contains(destinationIndex),
            abs(sourceIndex - destinationIndex) == 1
        else {
            return self
        }

        let orderedIndices = [sourceIndex, destinationIndex].sorted()
        let mergedElement = merge(self[orderedIndices[0]], self[orderedIndices[1]])
        let insertionIndex = orderedIndices[0]
        let removingIndices = orderedIndices.sorted(by: >)
        var elements = self

        for index in removingIndices {
            elements.remove(at: index)
        }

        elements.insert(mergedElement, at: insertionIndex)
        return elements
    }
}

private struct WrappingHStack: Layout {
    var alignment: HorizontalAlignment = .center
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let rows = rows(for: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? rows.map(\.size.width).max() ?? 0,
            height: rows.reduce(0) { height, row in
                height + row.size.height
            } + verticalSpacing * CGFloat(max(rows.count - 1, 0))
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = rows(for: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = xOffset(for: row, in: bounds)

            for element in row.elements {
                let point = CGPoint(
                    x: x,
                    y: y + (row.size.height - element.size.height) / 2
                )

                subviews[element.index].place(
                    at: point,
                    anchor: .topLeading,
                    proposal: ProposedViewSize(element.size)
                )

                x += element.size.width + horizontalSpacing
            }

            y += row.size.height + verticalSpacing
        }
    }

    private func rows(
        for proposal: ProposedViewSize,
        subviews: Subviews
    ) -> [Row] {
        let availableWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var currentRow = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let element = Element(index: index, size: size)
            let nextWidth = currentRow.size.width + (currentRow.elements.isEmpty ? 0 : horizontalSpacing) + size.width

            if nextWidth > availableWidth, currentRow.elements.isEmpty == false {
                rows.append(currentRow)
                currentRow = Row(element)
            } else {
                currentRow.append(element, spacing: horizontalSpacing)
            }
        }

        if currentRow.elements.isEmpty == false {
            rows.append(currentRow)
        }

        return rows
    }

    private func xOffset(for row: Row, in bounds: CGRect) -> CGFloat {
        switch alignment {
        case .leading:
            bounds.minX
        case .trailing:
            bounds.maxX - row.size.width
        default:
            bounds.midX - row.size.width / 2
        }
    }

    private struct Row {
        var elements: [Element] = []
        var size: CGSize = .zero

        init() {}

        init(_ element: Element) {
            elements = [element]
            size = element.size
        }

        mutating func append(_ element: Element, spacing: CGFloat) {
            size.width += (elements.isEmpty ? 0 : spacing) + element.size.width
            size.height = max(size.height, element.size.height)
            elements.append(element)
        }
    }

    private struct Element {
        let index: Int
        let size: CGSize
    }
}
