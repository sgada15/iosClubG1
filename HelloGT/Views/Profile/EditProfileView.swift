//
//  EditProfileView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Binding var profile: UserProfile
    @EnvironmentObject var authManager: AuthenticationManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var newInterest = ""
    @State private var newClub = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var saveError: String?
    
    // Photo picker states
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploadingPhoto = false
    @State private var showPhotoError = false
    @State private var photoErrorMessage = ""
    
    // Constants
    private let graduationYears = ["2025", "2026", "2027", "2028", "2029", "2030"]
    private let personalityQuestions = [
        "What do you do in your free time?",
        "What are 3 words to describe yourself?",
        "What are you passionate about?",
        "What is your favorite study spot?"
    ]
    
    // Computed Properties
    private var isFormValid: Bool {
        !profile.name.isEmpty &&
        !profile.username.isEmpty &&
        !profile.major.isEmpty &&
        !profile.year.isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable Form Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Profile Photo Section
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                // Current photo preview
                                Group {
                                    if let profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .scaledToFill()
                                    } else if let photoURL = profile.profilePhotoURL, !photoURL.isEmpty {
                                        AsyncImage(url: URL(string: photoURL)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        }
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Profile Photo")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Text("Choose a photo that represents you")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 12) {
                                        PhotosPicker(
                                            selection: $selectedPhoto,
                                            matching: .images,
                                            photoLibrary: .shared()
                                        ) {
                                            Text("Change Photo")
                                                .font(.caption)
                                                .foregroundColor(.accentColor)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.accentColor.opacity(0.1))
                                                .cornerRadius(6)
                                        }
                                        .disabled(isUploadingPhoto)
                                        
                                        if isUploadingPhoto {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
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
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for save button
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
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
        .alert("Photo Error", isPresented: $showPhotoError) {
            Button("Try Again") {
                selectedPhoto = nil
                profileImage = nil
            }
            Button("OK") { }
        } message: {
            Text(photoErrorMessage)
        }
        .onChange(of: selectedPhoto) { _ in
            loadSelectedPhoto()
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
                // If there's a new profile image, upload it first
                if let profileImage = profileImage {
                    print("📸 Uploading new profile image...")
                    
                    // Delete old image if it exists
                    if let oldURL = profile.profilePhotoURL, !oldURL.isEmpty {
                        try? await authManager.deleteOldProfileImage(url: oldURL)
                    }
                    
                    // Upload new image
                    let newImageURL = try await authManager.uploadProfileImage(profileImage, userId: profile.id)
                    profile.profilePhotoURL = newImageURL
                    
                    print("✅ Profile image uploaded successfully")
                }
                
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
    
    private func loadSelectedPhoto() {
        guard let selectedPhoto else {
            profileImage = nil
            return
        }
        
        isUploadingPhoto = true
        
        Task {
            do {
                if let data = try await selectedPhoto.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        let compressedImage = await compressImage(image)
                        
                        await MainActor.run {
                            profileImage = compressedImage
                            isUploadingPhoto = false
                        }
                    } else {
                        await MainActor.run {
                            photoErrorMessage = "Unable to process the selected image"
                            showPhotoError = true
                            isUploadingPhoto = false
                        }
                    }
                } else {
                    await MainActor.run {
                        photoErrorMessage = "Unable to load the selected image"
                        showPhotoError = true
                        isUploadingPhoto = false
                    }
                }
            } catch {
                await MainActor.run {
                    photoErrorMessage = "Error loading image: \(error.localizedDescription)"
                    showPhotoError = true
                    isUploadingPhoto = false
                }
            }
        }
    }
    
    private func compressImage(_ image: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let targetSize = CGSize(width: 600, height: 600)
                
                // Calculate new size maintaining aspect ratio
                let widthRatio = targetSize.width / image.size.width
                let heightRatio = targetSize.height / image.size.height
                let ratio = min(widthRatio, heightRatio)
                
                let newSize = CGSize(
                    width: image.size.width * ratio,
                    height: image.size.height * ratio
                )
                
                // Create compressed image
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1.0
                
                let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
                let compressedImage = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }
                
                // Further compress with JPEG
                if let jpegData = compressedImage.jpegData(compressionQuality: 0.8),
                   let finalImage = UIImage(data: jpegData) {
                    continuation.resume(returning: finalImage)
                } else {
                    continuation.resume(returning: compressedImage)
                }
            }
        }
    }
}

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

// Alternative: Use a ViewModifier approach if TextFieldStyle doesn't work
extension View {
    func customTextFieldStyle() -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

struct InterestTagsView: View {
    @Binding var interests: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(interests.indices, id: \.self) { index in
                HStack {
                    Text(interests[index])
                        .font(.caption)
                        .lineLimit(1)
                    
                    Button {
                        interests.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(16)
            }
        }
    }
}

struct ClubTagsView: View {
    @Binding var clubs: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
            ForEach(clubs.indices, id: \.self) { index in
                HStack {
                    Text(clubs[index])
                        .font(.caption)
                        .lineLimit(1)
                    
                    Button {
                        clubs.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(16)
            }
        }
    }
}
