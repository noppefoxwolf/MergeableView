import MergeableView
import SwiftUI

struct ContentView: View {
    @State
    private var tokens = Token.initialTokens

    @State
    var selections: [Token] = []

    var body: some View {
        NavigationStack(root: {
            Form {
                Section {
                    HStack {
                        ForEach(selections) { selection in
                            Button {
                                selections.removeAll(where: { $0.id == selection.id })
                            } label: {
                                Label(selection.text, systemImage: "xmark")
                                    .bold()
                            }
                            .buttonStyle(.glass)
                        }
                    }
                }

                Section {
                    container()
                }
            }
            .animation(.default, value: tokens)
            .animation(.default, value: selections)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Reset", action: resetTokens)
                }
            }
        })
    }

    @ViewBuilder
    func container() -> some View {
        MergableContainer {
            VStack(alignment: .leading) {
                ForEach(tokens) { token in
                    Button(
                        action: {
                            tokens.removeAll(where: { $0.id == token.id })
                            selections.append(token)
                        },
                        label: {
                            Label(token.text, systemImage: "plus")
                                .bold()
                        }
                    )
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
    }

    private func resetTokens() {
        tokens = Token.initialTokens
        selections = []
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

struct TokenView: View {
    let token: Token

    init(_ token: Token) {
        self.token = token
    }

    var body: some View {
        Text(token.text)
            .bold()
            .padding()
            .glassEffect(.regular.interactive())
    }
}
