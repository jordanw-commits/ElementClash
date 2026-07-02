//
//  PuzzleLevelSelectView.swift
//  Orbito
//
//  Created by Jordan Westlund on 7/1/26.
//

import SwiftUI

struct PuzzleLevelSelectView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectPuzzle: (PuzzleLevel) -> Void

    var body: some View {
        List(PuzzleLevels.all, id: \.id) { level in
            Button {
                dismiss()
                onSelectPuzzle(level)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chamber \(level.id)")
                        .font(.headline)
                    Text(level.chamberName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Puzzle Mode")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}
