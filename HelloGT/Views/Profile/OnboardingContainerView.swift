//
//  OnboardingContainerView.swift
//  BuzzBuddy
//
//  Created by Sanaa on 11/18/25.
//

import SwiftUI
import FirebaseAuth

struct OnboardingContainerView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentStep = 0
    @State private var profile: UserProfile
    @State private var isCompleting = false
    @State private var profileImage: UIImage? // Add this to store the selected image
    
    init() {
        // Initialize with current user's basic info
        _profile = State(initialValue: UserProfile(
            id: "",
            profilePhotoURL: nil,
            name: "",
            username: "",
            year: "",
            major: "",
            bio: "",
            interests: [],
            clubs: [],
            personalityAnswers: ["", "", "", ""]
        ))
    }
    
    private let totalSteps = 6
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - GT themed
                LinearGradient.gtBackgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    OnboardingProgressView(
                        currentStep: currentStep,
                        totalSteps: totalSteps
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        WelcomeStepView(
                            onNext: { goToNextStep() }
                        )
                        .tag(0)
                        
                        BasicInfoStepView(
                            profile: $profile,
                            onNext: { goToNextStep() },
                            onBack: { goToPreviousStep() },
                            onImageSelected: { image in
                                profileImage = image
                            }
                        )
                        .tag(1)
                        
                        BioStepView(
                            profile: $profile,
                            onNext: { goToNextStep() },
                            onBack: { goToPreviousStep() }
                        )
                        .tag(2)
                        
                        InterestsStepView(
                            profile: $profile,
                            onNext: { goToNextStep() },
                            onBack: { goToPreviousStep() }
                        )
                        .tag(3)
                        
                        ClubsStepView(
                            profile: $profile,
                            onNext: { goToNextStep() },
                            onBack: { goToPreviousStep() }
                        )
                        .tag(4)
                        
                        PersonalityStepView(
                            profile: $profile,
                            onNext: { completeOnboarding() },
                            onBack: { goToPreviousStep() },
                            isCompleting: isCompleting
                        )
                        .tag(5)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupInitialProfile()
            }
        }
    }
    
    private func setupInitialProfile() {
        guard let user = authManager.user else { return }
        profile.id = user.uid
        if let displayName = user.displayName, !displayName.isEmpty {
            profile.name = displayName
        }
        if let email = user.email {
            profile.username = String(email.split(separator: "@").first ?? "")
        }
    }
    
    private func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }
    
    private func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = max(currentStep - 1, 0)
        }
    }
    
    private func completeOnboarding() {
        isCompleting = true
        
        Task {
            do {
                // First, upload profile image if one was selected
                if let profileImage = profileImage {
                    print("📸 Uploading profile image during onboarding...")
                    let imageURL = try await authManager.uploadProfileImage(profileImage, userId: profile.id)
                    profile.profilePhotoURL = imageURL
                    print("✅ Profile image uploaded successfully")
                }
                
                // Save the complete profile
                try await authManager.saveUserProfile(profile)
                
                // Small delay to ensure Firebase write completes
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    print("✅ Onboarding completed for \(profile.name)")
                    isCompleting = false
                    
                    // Post a notification to trigger MainTabView refresh
                    NotificationCenter.default.post(name: .profileCompleted, object: nil)
                }
                
            } catch {
                await MainActor.run {
                    isCompleting = false
                    print("❌ Failed to complete onboarding: \(error)")
                    // TODO: Show error message
                }
            }
        }
    }
}

struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Setting up your profile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(currentStep + 1) of \(totalSteps)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.gtGold)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let profileCompleted = Notification.Name("profileCompleted")
}
