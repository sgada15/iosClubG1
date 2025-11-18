import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "sparkles")
                }
                .environmentObject(authManager)

            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }

            SavedProfilesView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
                .environmentObject(authManager)

            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .environmentObject(authManager)

            MyProfileView()
                .tabItem {
                    Label("My Profile", systemImage: "person.crop.circle")
                }
                .environmentObject(authManager)
        }
        .tint(.accentColor)
    }
}
