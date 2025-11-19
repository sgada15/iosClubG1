//
//  EditProfileView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
// - also do a create profile page if you dont have ur own profiel yet

import SwiftUI

struct EditProfileView: View {
    @Binding var profile: UserProfile
    @EnvironmentObject var authManager: AuthenticationManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var newInterest = ""
    @State private var newClub = ""
    @State private var isLoading = false
    @State private var saveError: String?

    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Name", text: $profile.name)
                TextField("Username", text: $profile.username)
                TextField("Major", text: $profile.major)
                TextField("Year", text: $profile.year)
            }

            Section(header: Text("Interests")) {
                ForEach(profile.interests, id: \.self) { interest in
                    Text(interest)
                }
                .onDelete { index in
                    profile.interests.remove(atOffsets: index)
                }

                HStack {
                    TextField("Add new interest", text: $newInterest)
                    Button("Add") {
                        guard !newInterest.isEmpty else { return }
                        profile.interests.append(newInterest)
                        newInterest = ""
                    }
                }
            }

            Section(header: Text("Clubs")) {
                ForEach(profile.clubs, id: \.self) { club in
                    Text(club)
                }
                .onDelete { index in
                    profile.clubs.remove(atOffsets: index)
                }

                HStack {
                    TextField("Add new club", text: $newClub)
                    Button("Add") {
                        guard !newClub.isEmpty else { return }
                        profile.clubs.append(newClub)
                        newClub = ""
                    }
                }
            }

            Section(header: Text("Bio")) {
                TextEditor(text: $profile.bio)
                    .frame(minHeight: 120)
            }

            Section(header: Text("Personality Questions")) {
                VStack(alignment: .leading, spacing: 16) {
                    personalityQuestion(
                        number: 1,
                        question: "What do you do in your free time?",
                        binding: Binding(
                            get: { profile.personalityAnswers.count > 0 ? profile.personalityAnswers[0] : "" },
                            set: { 
                                ensurePersonalityAnswersSize()
                                profile.personalityAnswers[0] = $0 
                            }
                        )
                    )
                    
                    personalityQuestion(
                        number: 2,
                        question: "What are 3 words to describe yourself?",
                        binding: Binding(
                            get: { profile.personalityAnswers.count > 1 ? profile.personalityAnswers[1] : "" },
                            set: { 
                                ensurePersonalityAnswersSize()
                                profile.personalityAnswers[1] = $0 
                            }
                        )
                    )
                    
                    personalityQuestion(
                        number: 3,
                        question: "What are you passionate about?",
                        binding: Binding(
                            get: { profile.personalityAnswers.count > 2 ? profile.personalityAnswers[2] : "" },
                            set: { 
                                ensurePersonalityAnswersSize()
                                profile.personalityAnswers[2] = $0 
                            }
                        )
                    )
                    
                    personalityQuestion(
                        number: 4,
                        question: "What is your favorite study spot?",
                        binding: Binding(
                            get: { profile.personalityAnswers.count > 3 ? profile.personalityAnswers[3] : "" },
                            set: { 
                                ensurePersonalityAnswersSize()
                                profile.personalityAnswers[3] = $0 
                            }
                        )
                    )
                }
            }

            Section(header: Text("Profile Picture")) {
                // Placeholder - you can add an image picker later
                HStack {
                    AsyncImage(url: URL(string: profile.profilePhotoURL ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())

                    Text("Tap to change (coming soon)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Save Error", isPresented: .constant(saveError != nil)) {
            Button("OK") {
                saveError = nil
            }
        } message: {
            Text(saveError ?? "")
        }
    }
    
    private func saveProfile() {
        isLoading = true
        saveError = nil
        
        Task {
            do {
                try await authManager.saveUserProfile(profile)
                await MainActor.run {
                    isLoading = false
                    print("✅ Successfully saved profile for \(profile.name)")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    saveError = "Failed to save profile: \(error.localizedDescription)"
                    print("❌ Failed to save profile: \(error)")
                }
            }
        }
    }
    
    private func ensurePersonalityAnswersSize() {
        while profile.personalityAnswers.count < 4 {
            profile.personalityAnswers.append("")
        }
    }
    
    @ViewBuilder
    private func personalityQuestion(number: Int, question: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number). \(question)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField("Your answer...", text: binding, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }
}
