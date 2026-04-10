import SwiftUI

struct PasteLinkView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PasteLinkViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Input card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("URL or Text")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        ZStack(alignment: .topLeading) {
                            if viewModel.input.isEmpty {
                                Text("Paste a link, QR content, or any text…")
                                    .foregroundStyle(.tertiary)
                                    .font(.body)
                                    .padding(.top, 10)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $viewModel.input)
                                .font(.body.monospaced())
                                .scrollContentBackground(.hidden)
                                .focused($inputFocused)
                                .frame(minHeight: 110, alignment: .top)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(14)
                        .background(Color(UIColor.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 14))
                    }

                    // Paste from clipboard shortcut
                    if !viewModel.input.isEmpty {
                        Button(role: .destructive) {
                            viewModel.input = ""
                        } label: {
                            Label("Clear", systemImage: "xmark.circle")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Button {
                        if let str = UIPasteboard.general.string, !str.isEmpty {
                            viewModel.input = str
                        }
                    } label: {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    .controlSize(.large)

                    Button {
                        inputFocused = false
                        viewModel.inspect()
                    } label: {
                        Label("Inspect", systemImage: "magnifyingglass.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0, green: 0.83, blue: 1))
                    .controlSize(.large)
                    .disabled(viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Inspect Link")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $viewModel.result) { result in
                InspectionResultView(result: result)
            }
        }
        .onReceive(viewModel.$result.compactMap { $0 }) { appState.record($0) }
    }
}
