//
//  DiscoverFilterSheet.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

struct DiscoverFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: DiscoverFilters
    private let onApply: (DiscoverFilters) -> Void

    init(filters: DiscoverFilters, onApply: @escaping (DiscoverFilters) -> Void) {
        _draft = State(initialValue: filters)
        self.onApply = onApply
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var fromYears: [Int] {
        Array((1950...currentYear).reversed())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    fromYearRow
                    toYearRow
                } header: {
                    Text("Release year")
                }

                Section {
                    ratingPicker
                } header: {
                    Text("Minimum rating")
                }

                Section {
                    sortPicker
                } header: {
                    Text("Sort by")
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

    private var fromYearRow: some View {
        HStack {
            Text("From")
            Spacer()
            Menu {
                Button("Any") {
                    draft.yearRange = nil
                }
                ForEach(fromYears, id: \.self) { year in
                    Button(String(year)) {
                        let upper = max(year, min(draft.yearRange?.upperBound ?? currentYear, currentYear))
                        draft.yearRange = year...upper
                    }
                }
            } label: {
                Text(draft.yearRange.map { String($0.lowerBound) } ?? "Any")
            }
            .accessibilityLabel("From year")
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
