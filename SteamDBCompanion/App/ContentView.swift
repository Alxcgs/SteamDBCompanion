import SwiftUI

struct ContentView: View {
    
    let dataSource: SteamDBDataSource
    
    var body: some View {
        HomeView(dataSource: dataSource)
    }
}

#Preview {
    ContentView(dataSource: MockSteamDBDataSource())
}
