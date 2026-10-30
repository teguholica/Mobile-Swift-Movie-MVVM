//
//  CategoryFilterSheet.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

struct CategoryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let genres: [Genre]
    private let isTextMode: Bool
    private let onApply: ([Int]) -> Void

    @State private var selection: Set<Int>

    private let columns = [
        GridItem(.adaptive(minimum: 96), spacing: 8)
    ]

    init(
        selectedGenreIds: [Int],
        genres: [Genre],
        isTextMode: Bool,
        onApply: @escaping ([Int]) -> Void
    ) {
        self.genres = genres
        self.isTextMode = isTextMode
        self.onApply = onApply
        _selection = State(initialValue: Set(selectedGenreIds))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if isTextMode {
                    Text("Choosing a category clears the search and switches to category browsing.")
                        .font(.footnote)
                        .foregroundStyle(CinemaTokens.Colors.textSecondary)
                        .padding(.horizontal, 16)
                }

                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        ForEach(genres) { genre in
                            Button {
                                toggle(genre)
                            } label: {
                                genreChip(genre)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selection.contains(genre.id) ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        selection.removeAll()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onApply(orderedSelection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var orderedSelection: [Int] {
        genres.map(\.id).filter { selection.contains($0) }
    }

    private func toggle(_ genre: Genre) {
        if selection.contains(genre.id) {
            selection.remove(genre.id)
        } else {
            selection.insert(genre.id)
        }
    }

    private func genreChip(_ genre: Genre) -> some View {
        let isSelected = selection.contains(genre.id)

        return Text(genre.name)
            .font(.caption.weight(isSelected ? .bold : .medium))
            .foregroundStyle(isSelected ? .black : CinemaTokens.Colors.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(isSelected ? CinemaTokens.Colors.gold : CinemaTokens.Colors.elevated)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
            )
    }
}
