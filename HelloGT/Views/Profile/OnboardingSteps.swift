//
//  OnboardingSteps.swift
//  BuzzBuddy
//
//  Created by Assistant on 11/18/25.
//

import SwiftUI
import PhotosUI

// MARK: - Welcome Step
struct WelcomeStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundColor(.gtGold)
                
                VStack(spacing: 12) {
                    Text("Welcome to BuzzBuddy!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Where the buzz at? Let's create your profile to connect with fellow Yellow Jackets")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button("Get Started") {
                    onNext()
                }
                .buttonStyle(.gtPrimary)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                
                Text("This will take about 2 minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.gtBackgroundGradient)
    }
}

// MARK: - Basic Info Step
struct BasicInfoStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    let onImageSelected: ((UIImage?) -> Void)? // Add callback for image
    
    @State private var nameValid = false
    @State private var usernameValid = false
    @State private var majorValid = false
    @State private var yearValid = false
    @State private var photoValid = false
    
    // Photo picker states
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploadingPhoto = false
    @State private var showPhotoError = false
    @State private var photoErrorMessage = ""
    
    private var isStepValid: Bool {
        nameValid && usernameValid && majorValid && yearValid && photoValid
    }
    
    private let years = ["2025", "2026", "2027", "2028", "2029", "2030"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Basic Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Help other Yellow Jackets find you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    // Profile Photo Section
                    ProfilePhotoPickerField(
                        selectedPhoto: $selectedPhoto,
                        profileImage: $profileImage,
                        isValid: $photoValid,
                        isUploading: $isUploadingPhoto,
                        onError: { message in
                            photoErrorMessage = message
                            showPhotoError = true
                        }
                    )
                    
                    ValidatedTextField(
                        title: "Full Name",
                        text: $profile.name,
                        isValid: $nameValid,
                        validation: { !$0.isEmpty },
                        placeholder: "John Doe"
                    )
                    
                    ValidatedTextField(
                        title: "Username",
                        text: $profile.username,
                        isValid: $usernameValid,
                        validation: { !$0.isEmpty && $0.count >= 3 },
                        placeholder: "johndoe"
                    )
                    
                    ValidatedTextField(
                        title: "Major",
                        text: $profile.major,
                        isValid: $majorValid,
                        validation: { !$0.isEmpty },
                        placeholder: "Enter your major"
                    )
                    
                    YearPickerField(
                        selectedYear: $profile.year,
                        isValid: $yearValid,
                        years: years
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 100)
                
                // Navigation
                HStack(spacing: 20) {
                    Button("Back") {
                        onBack()
                    }
                    .buttonStyle(.gtSecondary)
                    .frame(maxWidth: .infinity)
                    .disabled(isUploadingPhoto)
                    
                    Button("Continue") {
                        onNext()
                    }
                    .buttonStyle(.gtPrimary)
                    .frame(maxWidth: .infinity)
                    .disabled(!isStepValid || isUploadingPhoto)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.gtBackgroundGradient)
        .alert("Photo Upload Error", isPresented: $showPhotoError) {
            Button("Try Again") {
                selectedPhoto = nil
                profileImage = nil
                photoValid = false
            }
            Button("OK") { }
        } message: {
            Text(photoErrorMessage)
        }
        .onChange(of: profileImage) { newImage in
            onImageSelected?(newImage)
        }
    }
}

// MARK: - Bio Step
struct BioStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var bioValid = false
    
    private var characterCount: Int {
        profile.bio.count
    }
    
    private var isStepValid: Bool {
        bioValid && characterCount >= 20
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("Tell Us About Yourself")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Write a brief bio to help others get to know you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            
            // Form
            VStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gtCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gtPastelYellow.opacity(0.3), lineWidth: 1)
                        )
                        .frame(height: 120)
                    
                    TextEditor(text: $profile.bio)
                        .padding(12)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                        .onChange(of: profile.bio) { _ in
                            bioValid = !profile.bio.isEmpty
                        }
                    
                    if profile.bio.isEmpty {
                        Text("Share your interests, what you're studying, or what you love about GT...")
                            .foregroundColor(.secondary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
                
                HStack {
                    Text("\(characterCount)/20 minimum")
                        .font(.caption)
                        .foregroundColor(characterCount >= 20 ? .gtSuccess : .secondary)
                    
                    Spacer()
                    
                    if characterCount >= 20 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.gtSuccess)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 20) {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.gtSecondary)
                .frame(maxWidth: .infinity)
                
                Button("Continue") {
                    onNext()
                }
                .buttonStyle(.gtPrimary)
                .frame(maxWidth: .infinity)
                .disabled(!isStepValid)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.gtBackgroundGradient)
    }
}

// MARK: - Helper Components
struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    @Binding var isValid: Bool
    let validation: (String) -> Bool
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gtSuccess)
                        .font(.subheadline)
                }
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(GTTextFieldStyle())
                .onChange(of: text) { newValue in
                    isValid = validation(newValue)
                }
                .onAppear {
                    isValid = validation(text)
                }
        }
    }
}

struct YearPickerField: View {
    @Binding var selectedYear: String
    @Binding var isValid: Bool
    let years: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Graduation Year")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gtSuccess)
                        .font(.subheadline)
                }
            }
            
            Menu {
                ForEach(years, id: \.self) { year in
                    Button(year) {
                        selectedYear = year
                        isValid = true
                    }
                }
            } label: {
                HStack {
                    Text(selectedYear.isEmpty ? "Select graduation year" : selectedYear)
                        .foregroundColor(selectedYear.isEmpty ? .secondary : .primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gtCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gtPastelYellow.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
            }
        }
        .onAppear {
            isValid = !selectedYear.isEmpty
        }
    }
}

// MARK: - Interests Step
struct InterestsStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var newInterest = ""
    
    private var isStepValid: Bool {
        profile.interests.count >= 2
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("Your Interests")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add at least 2 interests to help others connect with you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            
            // Form
            VStack(spacing: 20) {
                // Add new interest
                HStack {
                    TextField("Add an interest", text: $newInterest)
                        .textFieldStyle(GTTextFieldStyle())
                    
                    Button("Add") {
                        guard !newInterest.isEmpty,
                              !profile.interests.contains(newInterest) else { return }
                        profile.interests.append(newInterest)
                        newInterest = ""
                    }
                    .buttonStyle(.gtPrimary)
                    .disabled(newInterest.isEmpty)
                }
                
                // Current interests
                if !profile.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Interests (\(profile.interests.count)/2+ required)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if isStepValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.gtSuccess)
                                    .font(.subheadline)
                            }
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(profile.interests, id: \.self) { interest in
                                InterestChip(
                                    text: interest,
                                    onRemove: {
                                        profile.interests.removeAll { $0 == interest }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 20) {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.gtSecondary)
                .frame(maxWidth: .infinity)
                
                Button("Continue") {
                    onNext()
                }
                .buttonStyle(.gtPrimary)
                .frame(maxWidth: .infinity)
                .disabled(!isStepValid)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.gtBackgroundGradient)
    }
}

// MARK: - Clubs Step
struct ClubsStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var newClub = ""
    
    private var isStepValid: Bool {
        profile.clubs.count >= 1
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Text("Your Clubs")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add at least 1 club or organization you're part of")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 40)
            
            // Form
            VStack(spacing: 20) {
                // Add new club
                HStack {
                    TextField("Add a club or organization", text: $newClub)
                        .textFieldStyle(GTTextFieldStyle())
                    
                    Button("Add") {
                        guard !newClub.isEmpty,
                              !profile.clubs.contains(newClub) else { return }
                        profile.clubs.append(newClub)
                        newClub = ""
                    }
                    .buttonStyle(.gtPrimary)
                    .disabled(newClub.isEmpty)
                }
                
                // Current clubs
                if !profile.clubs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Clubs (\(profile.clubs.count)/1+ required)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if isStepValid {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.gtSuccess)
                                    .font(.subheadline)
                            }
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(profile.clubs, id: \.self) { club in
                                InterestChip(
                                    text: club,
                                    onRemove: {
                                        profile.clubs.removeAll { $0 == club }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 20) {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.gtSecondary)
                .frame(maxWidth: .infinity)
                
                Button("Continue") {
                    onNext()
                }
                .buttonStyle(.gtPrimary)
                .frame(maxWidth: .infinity)
                .disabled(!isStepValid)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.gtBackgroundGradient)
    }
}

// MARK: - Personality Step
struct PersonalityStepView: View {
    @Binding var profile: UserProfile
    let onNext: () -> Void
    let onBack: () -> Void
    let isCompleting: Bool
    
    private var isStepValid: Bool {
        profile.personalityAnswers.allSatisfy { !$0.isEmpty }
    }
    
    private let questions = [
        "What do you do in your free time?",
        "What are 3 words to describe yourself?",
        "What are you passionate about?",
        "What is your favorite study spot?"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Personality Questions")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Help others get to know the real you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)
                
                // Questions
                VStack(spacing: 24) {
                    ForEach(0..<questions.count, id: \.self) { index in
                        OnboardingPersonalityQuestion(
                            number: index + 1,
                            question: questions[index],
                            answer: Binding(
                                get: {
                                    profile.personalityAnswers.count > index ? profile.personalityAnswers[index] : ""
                                },
                                set: { newValue in
                                    ensurePersonalityAnswersSize()
                                    profile.personalityAnswers[index] = newValue
                                }
                            )
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer(minLength: 100)
                
                // Navigation
                HStack(spacing: 20) {
                    Button("Back") {
                        onBack()
                    }
                    .buttonStyle(.gtSecondary)
                    .frame(maxWidth: .infinity)
                    .disabled(isCompleting)
                    
                    Button(isCompleting ? "Creating Profile..." : "Complete Profile") {
                        onNext()
                    }
                    .buttonStyle(.gtPrimary)
                    .frame(maxWidth: .infinity)
                    .disabled(!isStepValid || isCompleting)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient.gtBackgroundGradient)
    }
    
    private func ensurePersonalityAnswersSize() {
        while profile.personalityAnswers.count < 4 {
            profile.personalityAnswers.append("")
        }
    }
}

// MARK: - Helper Components
struct InterestChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.subheadline)
                .lineLimit(1)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gtPastelYellow.opacity(0.3))
        .overlay(
            Capsule()
                .stroke(Color.gtGold.opacity(0.4), lineWidth: 0.5)
        )
        .clipShape(Capsule())
    }
}

struct OnboardingPersonalityQuestion: View {
    let number: Int
    let question: String
    @Binding var answer: String
    
    private var isValid: Bool {
        !answer.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(number). \(question)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gtSuccess)
                        .font(.subheadline)
                }
            }
            
            TextField("Your answer...", text: $answer, axis: .vertical)
                .textFieldStyle(GTTextFieldStyle())
                .lineLimit(2...4)
        }
    }
}

struct ProfilePhotoPickerField: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var profileImage: UIImage?
    @Binding var isValid: Bool
    @Binding var isUploading: Bool
    let onError: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Profile Photo")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isUploading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gtSuccess)
                        .font(.subheadline)
                }
            }
            
            HStack(spacing: 16) {
                // Profile image preview
                Group {
                    if let profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gtPastelYellow.opacity(0.5), lineWidth: 2)
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(profileImage != nil ? "Photo selected" : "Add your photo")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("This helps other Yellow Jackets recognize you")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text(profileImage != nil ? "Change Photo" : "Select Photo")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gtGold.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gtGold.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(6)
                    }
                    .disabled(isUploading)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.gtCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gtPastelYellow.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .onChange(of: selectedPhoto) { _ in
            loadSelectedPhoto()
        }
    }
    
    private func loadSelectedPhoto() {
        guard let selectedPhoto else {
            profileImage = nil
            isValid = false
            return
        }
        
        isUploading = true
        
        Task {
            do {
                if let data = try await selectedPhoto.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        let compressedImage = await compressImage(image)
                        
                        await MainActor.run {
                            profileImage = compressedImage
                            isValid = true
                            isUploading = false
                        }
                    } else {
                        await MainActor.run {
                            onError("Unable to process the selected image")
                            isUploading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        onError("Unable to load the selected image")
                        isUploading = false
                    }
                }
            } catch {
                await MainActor.run {
                    onError("Error loading image: \(error.localizedDescription)")
                    isUploading = false
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
