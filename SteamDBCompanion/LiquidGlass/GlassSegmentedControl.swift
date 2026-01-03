import SwiftUI

/// A custom segmented control with glass styling.
public struct GlassSegmentedControl<T: Hashable & CustomStringConvertible>: View {
    
    @Binding var selection: T
    let options: [T]
    
    public init(selection: Binding<T>, options: [T]) {
        self._selection = selection
        self.options = options
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = option
                    }
                } label: {
                    Text(option.description)
                        .font(.subheadline)
                        .fontWeight(selection == option ? .bold : .regular)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selection == option ? .white : .secondary)
                        .background(
                            ZStack {
                                if selection == option {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LiquidGlassTheme.Colors.neonPrimary.opacity(0.3))
                                        .matchedGeometryEffect(id: "selection", in: namespace)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(LiquidGlassTheme.Colors.neonPrimary.opacity(0.5), lineWidth: 1)
                                                .matchedGeometryEffect(id: "border", in: namespace)
                                        )
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.2))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    @Namespace private var namespace
}

// Example usage
enum FilterOption: String, CaseIterable, CustomStringConvertible {
    case all = "All"
    case games = "Games"
    case dlc = "DLC"
    
    var description: String { rawValue }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        GlassSegmentedControl(selection: .constant(FilterOption.all), options: FilterOption.allCases)
            .padding()
    }
}
