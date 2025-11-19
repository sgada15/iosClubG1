//
//  EditProfileView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Invisible placeholder for symmetry
                    Text("Cancel")
                        .foregroundColor(.clear)
                }
                .padding()
                
                // Scrollable Form Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Profile Photo Section
                        VStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            
                            Text("Tap to change (coming soon)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                        
                        // Basic Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Basic Info")
                            
                            // Name *
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Name")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField("Enter your full name", text: $profile.name)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Username *
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Username")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField("Enter your username", text: $profile.username)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.none)
                            }
                            
                            // Graduation Year * (Picker)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Graduation Year")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                
                                Menu {
                                    ForEach(graduationYears, id: \.self) { year in
                                        Button(year) {
                                            profile.year = year
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(profile.year.isEmpty ? "Select graduation year" : profile.year)
                                            .foregroundColor(profile.year.isEmpty ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Major *
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Major")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                TextField("Enter your major", text: $profile.major)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Bio (Optional)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bio")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextEditor(text: $profile.bio)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Interests Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Interests")
                            
                            // Add Interest Field
                            HStack {
                                TextField("Add new interest", text: $newInterest)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                Button("Add") {
                                    addInterest()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            
                            // Display Interests
                            if !profile.interests.isEmpty {
                                InterestTagsView(interests: $profile.interests)
                            }
                        }
                        
                        // Clubs/Organizations Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Clubs/Organizations")
                            
                            // Add Club Field
                            HStack {
                                TextField("Add new club/organization", text: $newClub)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                Button("Add") {
                                    addClub()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(newClub.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            
                            // Display Clubs
                            if !profile.clubs.isEmpty {
                                ClubTagsView(clubs: $profile.clubs)
                            }
                        }
                        
                        // Personality Questions Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Personality Questions")
                            
                            ForEach(0..<personalityQuestions.count, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(index + 1). \(personalityQuestions[index])")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    TextField("Your answer...", text: Binding(
                                        get: {
                                            index < profile.personalityAnswers.count ? profile.personalityAnswers[index] : ""
                                        },
                                        set: { newValue in
                                            // Ensure personalityAnswers has enough elements
                                            while profile.personalityAnswers.count <= index {
                                                profile.personalityAnswers.append("")
                                            }
                                            profile.personalityAnswers[index] = newValue
                                        }
                                    ))
                                    .textFieldStyle(CustomTextFieldStyle())
                                }
                            }
                        }
                        
                        // Bottom padding to account for fixed save button
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal)
                }
                
                // Fixed Save Button at Bottom
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: saveProfile) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isSaving ? "Saving..." : "Save Profile")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSaving)
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
        }
        .alert("Save Error", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            if let error = saveError {
                Text(error)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func addInterest() {
        let trimmedInterest = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInterest.isEmpty && !profile.interests.contains(trimmedInterest) else { return }
        
        profile.interests.append(trimmedInterest)
        newInterest = ""
    }
    
    private func addClub() {
        let trimmedClub = newClub.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClub.isEmpty && !profile.clubs.contains(trimmedClub) else { return }
        
        profile.clubs.append(trimmedClub)
        newClub = ""
    }
    
    private func saveProfile() {
        isSaving = true
        saveError = nil
        
        print("💾 Saving profile: \(profile.name) (ID: \(profile.id))")
        
        Task {
            do {
                try await authManager.saveUserProfile(profile)
                print("✅ Profile saved successfully")
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("❌ Failed to save profile: \(error)")
                await MainActor.run {
                    isSaving = false
                    saveError = "Failed to save profile: \(error.localizedDescription)"
                }
            }
        }
    }
}
