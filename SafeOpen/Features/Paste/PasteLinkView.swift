import SwiftUI

struct PasteLinkView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PasteLinkViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Paste or type a URL", text: $viewModel.input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)

                Button("Inspect") {
                    viewModel.inspect()
                }
                .disabled(viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Paste Link")
            .navigationDestination(item: $viewModel.result) { result in
                InspectionResultView(result: result)
            }
        }
        .onReceive(viewModel.$result.compactMap { $0 }) { result in
            appState.record(result)
        }
    }
}
