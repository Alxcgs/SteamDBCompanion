import SwiftUI

/// Device type helpers for adaptive layouts
public struct DeviceInfo {
    
    public static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    public static var horizontalSizeClass: UIUserInterfaceSizeClass {
        UIScreen.main.traitCollection.horizontalSizeClass
    }
    
    /// Number of columns based on device and size class
    public static func columns(forWidth width: CGFloat) -> Int {
        if isIPad {
            return width > 900 ? 3 : 2
        }
        return 1
    }
    
    /// Adaptive padding based on device
    public static var padding: CGFloat {
        isIPad ? 24 : 16
    }
    
    /// Card width for grids
    public static func cardWidth(totalWidth: CGFloat, columns: Int) -> CGFloat {
        let spacing: CGFloat = isIPad ? 20 : 16
        let totalSpacing = spacing * CGFloat(columns + 1)
        return (totalWidth - totalSpacing) / CGFloat(columns)
    }
}

/// Adaptive grid layout
public struct AdaptiveGrid<Item: Identifiable, Content: View>: View {
    
    let items: [Item]
    let content: (Item) -> Content
    
    @State private var columns: Int = 1
    
    public init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: DeviceInfo.isIPad ? 20 : 16), count: DeviceInfo.columns(forWidth: geometry.size.width)),
                    spacing: DeviceInfo.isIPad ? 20 : 16
                ) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                .padding(DeviceInfo.padding)
            }
        }
    }
}
