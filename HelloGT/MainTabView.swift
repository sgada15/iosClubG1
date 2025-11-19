import SwiftUI
import FirebaseAuth

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var savedProfilesManager = SavedProfilesManager()
    
    @State private var currentUserProfile: UserProfile?
    @State private var isLoadingProfile = true
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if isLoadingProfile {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading your profile...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if showOnboarding || currentUserProfile?.isComplete != true {
                // Show onboarding for new users or incomplete profiles
                OnboardingContainerView()
                    .environmentObject(authManager)
            } else {
                // Main app content
                TabView {
                    ExploreView()
                        .tabItem {
                            Label("Explore", systemImage: "sparkles")
                        }
                        .environmentObject(authManager)
                        .environmentObject(notificationManager)
                        .environmentObject(savedProfilesManager)

                    EventsView()
                        .tabItem {
                            Label("Events", systemImage: "calendar")
                        }
                        .environmentObject(authManager)

                    SavedProfilesView()
                        .tabItem {
                            Label("Saved", systemImage: "bookmark")
                        }
                        .environmentObject(authManager)
                        .environmentObject(savedProfilesManager)

                    FriendsView()
                        .tabItem {
                            if notificationManager.unreadCount > 0 {
                                Label("Friends", systemImage: "person.2")
                                    .badge(notificationManager.unreadCount)
                            } else {
                                Label("Friends", systemImage: "person.2")
                            }
                        }
                        .environmentObject(authManager)
                        .environmentObject(notificationManager)

                    MyProfileView()
                        .tabItem {
                            Label("My Profile", systemImage: "person.crop.circle")
                        }
                        .environmentObject(authManager)
                }
                .tint(.accentColor)
                .onAppear {
                    setupNotificationManager()
                }
            }
        }
        .onAppear {
            loadCurrentUserProfile()
        }
        .onChange(of: authManager.user) { oldValue, newValue in
            loadCurrentUserProfile()
            // Reload saved profiles when user changes
            if newValue != nil {
                savedProfilesManager.reloadSavedProfiles()
            } else {
                savedProfilesManager.clearSavedProfiles()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileCompleted)) { _ in
            // Refresh profile after onboarding completion
            print("🔔 Received profile completion notification - refreshing...")
            loadCurrentUserProfile()
        }
    }
    
    private func loadCurrentUserProfile() {
        guard let user = authManager.user else {
            isLoadingProfile = false
            showOnboarding = true
            return
        }
        
        isLoadingProfile = true
        
        Task {
            do {
                if let loadedProfile = try await authManager.getCurrentUserProfile() {
                    await MainActor.run {
                        currentUserProfile = loadedProfile
                        showOnboarding = !loadedProfile.isComplete
                        isLoadingProfile = false
                        
                        print("✅ Loaded profile: \(loadedProfile.name)")
                        print("📋 Profile complete: \(loadedProfile.isComplete)")
                        print("🔍 Completion: \(Int(loadedProfile.completionPercentage * 100))%")
                    }
                } else {
                    // No profile exists - new user needs onboarding
                    await MainActor.run {
                        currentUserProfile = nil
                        showOnboarding = true
                        isLoadingProfile = false
                        print("🆕 No profile found - showing onboarding")
                    }
                }
            } catch {
                print("❌ Error loading profile: \(error)")
                await MainActor.run {
                    currentUserProfile = nil
                    showOnboarding = true
                    isLoadingProfile = false
                }
            }
        }
    }
    
    private func setupNotificationManager() {
        guard let user = authManager.user else { return }
        notificationManager.setCurrentUser(userId: user.uid)
    }
}
