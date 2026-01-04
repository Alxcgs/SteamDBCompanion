import SwiftUI

public struct AppLookupView: View {
    @State private var appIDText: String = ""
    private let dataSource: SteamDBDataSource

    public init(dataSource: SteamDBDataSource) {
        self.dataSource = dataSource
    }

    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("App Sections")
                    .font(.largeTitle.bold())
                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

                Text("Enter a Steam App ID to view full SteamDB sections.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)

                    TextField("App ID (e.g. 730)", text: $appIDText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )

                if let appID = Int(appIDText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    NavigationLink {
                        AppSectionsView(appID: appID, dataSource: dataSource)
                    } label: {
                        GlassButtonLabel(title: "Open Sections", icon: "rectangle.stack.fill")
                    }
                } else {
                    GlassButtonLabel(title: "Open Sections", icon: "rectangle.stack.fill")
                        .opacity(0.4)
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GlassButtonLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                .strokeBorder(Color.primary.opacity(0.5), lineWidth: 1)
        )
        .foregroundStyle(.primary)
    }
}

#Preview {
    NavigationStack {
        AppLookupView(dataSource: MockSteamDBDataSource())
    }
}
