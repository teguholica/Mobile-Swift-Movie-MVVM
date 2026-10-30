//
//  DiscoverFilterSheet.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

struct DiscoverFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: DiscoverFilters
    private let isTextMode: Bool
    private let currentYear: Int
    private let selectableYears: [Int]
    private let onApply: (DiscoverFilters) -> Void

    init(
        filters: DiscoverFilters,
        isTextMode: Bool,
        onApply: @escaping (DiscoverFilters) -> Void
    ) {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.currentYear = currentYear
        self.selectableYears = Array((1950...currentYear).reversed())
        _draft = State(initialValue: filters)
        self.isTextMode = isTextMode
        self.onApply = onApply
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
        Picker("Year", selection: $draft.searchYear) {
            Text("Any").tag(Int?.none)
            ForEach(selectableYears, id: \.self) { year in
                Text(String(year)).tag(Int?.some(year))
            }
        }
        .pickerStyle(.menu)
    }

    private var fromYearRow: some View {
        Picker("From", selection: fromSelection) {
            Text("Any").tag(Int?.none)
            ForEach(selectableYears, id: \.self) { year in
                Text(String(year)).tag(Int?.some(year))
            }
        }
        .pickerStyle(.menu)
    }

    private var toYearRow: some View {
        Picker("To", selection: toSelection) {
            Text("Any").tag(Int?.none)
            if let lowerBound = draft.yearRange?.lowerBound {
                ForEach(Array((lowerBound...currentYear).reversed()), id: \.self) { year in
                    Text(String(year)).tag(Int?.some(year))
                }
            }
        }
        .pickerStyle(.menu)
        .disabled(draft.yearRange == nil)
    }

    private var fromSelection: Binding<Int?> {
        Binding(
            get: { draft.yearRange?.lowerBound },
            set: { year in
                guard let year else {
                    draft.yearRange = nil
                    return
                }
                let upper = max(year, min(draft.yearRange?.upperBound ?? currentYear, currentYear))
                draft.yearRange = year...upper
            }
        )
    }

    private var toSelection: Binding<Int?> {
        Binding(
            get: {
                guard let yearRange = draft.yearRange else { return nil }
                return yearRange.upperBound == currentYear ? nil : yearRange.upperBound
            },
            set: { year in
                guard let lowerBound = draft.yearRange?.lowerBound else { return }
                let upper = year ?? currentYear
                draft.yearRange = lowerBound...max(lowerBound, upper)
            }
        )
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
}
