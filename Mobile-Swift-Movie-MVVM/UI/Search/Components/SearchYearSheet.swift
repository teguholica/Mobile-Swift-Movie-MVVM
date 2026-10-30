//
//  SearchYearSheet.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

struct SearchYearSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draftYear: Int?
    private let years: [Int]
    private let onApply: (Int?) -> Void

    init(selectedYear: Int?, onApply: @escaping (Int?) -> Void) {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = Array((1950...currentYear).reversed())
        _draftYear = State(initialValue: selectedYear)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Year", selection: $draftYear) {
                    Text("Any").tag(Int?.none)
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(Int?.some(year))
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .accessibilityLabel("Release year")

                Text("Applies to title searches.")
                    .font(.footnote)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)

                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .navigationTitle("Release year")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onApply(draftYear)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(340)])
    }
}
