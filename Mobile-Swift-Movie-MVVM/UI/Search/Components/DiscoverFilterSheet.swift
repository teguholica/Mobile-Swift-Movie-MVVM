//
//  DiscoverFilterSheet.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

struct DiscoverFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: DiscoverFilters
    private let isTextMode: Bool
    private let onApply: (DiscoverFilters) -> Void

    init(
        filters: DiscoverFilters,
        isTextMode: Bool,
        onApply: @escaping (DiscoverFilters) -> Void
    ) {
        _draft = State(initialValue: filters)
        self.isTextMode = isTextMode
        self.onApply = onApply
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var selectableYears: [Int] {
        Array((1950...currentYear).reversed())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isTextMode {
                        searchYearRow
                    } else {
                        fromYearRow
                        toYearRow
                    }
                } header: {
                    Text("Release year")
                }

                Section {
                    ratingPicker
                        .disabled(isTextMode)
                } header: {
                    Text("Minimum rating")
                } footer: {
                    if isTextMode {
                        Text("Rating filters apply to Discover only.")
                    }
                }

                Section {
                    sortPicker
                        .disabled(isTextMode)
                } header: {
                    Text("Sort by")
                } footer: {
                    if isTextMode {
                        Text("Sort applies to Discover only.")
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        draft = DiscoverFilters(genreIds: draft.genreIds)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var searchYearRow: some View {
        HStack {
            Text("Year")
            Spacer()
            yearMenu(label: draft.searchYear.map(String.init) ?? "Any") { year in
                draft.searchYear = year
            }
            .accessibilityLabel("Release year")
        }
    }

    private var fromYearRow: some View {
        HStack {
            Text("From")
            Spacer()
            yearMenu(label: draft.yearRange.map { String($0.lowerBound) } ?? "Any") { year in
                guard let year else {
                    draft.yearRange = nil
                    return
                }
                let upper = max(year, min(draft.yearRange?.upperBound ?? currentYear, currentYear))
                draft.yearRange = year...upper
            }
            .accessibilityLabel("From year")
        }
    }

    private func yearMenu(label: String, onSelect: @escaping (Int?) -> Void) -> some View {
        Menu {
            Button("Any") {
                onSelect(nil)
            }
            ForEach(selectableYears, id: \.self) { year in
                Button(String(year)) {
                    onSelect(year)
                }
            }
        } label: {
            Text(label)
        }
    }

    private var ratingPicker: some View {
        Picker("Minimum rating", selection: $draft.minRating) {
            Text("Any").tag(Double?.none)
            ForEach([6.0, 7.0, 8.0, 9.0], id: \.self) { rating in
                Text("\(Int(rating))+").tag(Double?.some(rating))
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Minimum rating")
    }

    private var sortPicker: some View {
        Picker("Sort by", selection: $draft.sort) {
            ForEach(DiscoverSort.allCases, id: \.self) { sort in
                Text(sort.title).tag(sort)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Sort by")
    }

    private var toYearLabel: String {
        guard let yearRange = draft.yearRange else { return "Any" }
        return yearRange.upperBound == currentYear ? "Any" : String(yearRange.upperBound)
    }

    private var toYearRow: some View {
        HStack {
            Text("To")
            Spacer()
            Menu {
                if let lower = draft.yearRange?.lowerBound {
                    Button("Any") {
                        draft.yearRange = lower...currentYear
                    }
                    ForEach(Array((lower...currentYear).reversed()), id: \.self) { year in
                        Button(String(year)) {
                            draft.yearRange = lower...year
                        }
                    }
                }
            } label: {
                Text(toYearLabel)
            }
            .disabled(draft.yearRange == nil)
            .accessibilityLabel("To year")
        }
    }
}
