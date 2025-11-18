//
//  AuthenticationManager.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/16/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    
    init() {
        // Check current user immediately on initialization
        self.user = Auth.auth().currentUser
        self.isSignedIn = Auth.auth().currentUser != nil
        
        if let currentUser = Auth.auth().currentUser {
            print("🔐 Found existing user: \(currentUser.email ?? "No email")")
        } else {
            print("🔐 No existing user found")
        }
        
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isSignedIn = user != nil
                print("🔐 Auth state changed: \(user?.email ?? "No user")")
            }
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate Gmail email
            guard email.hasSuffix("@gmail.com") else {
                throw AuthError.invalidGmailEmail
            }
            
            // Create user account
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user
            
            // Update display name with full name
            let fullName = "\(firstName) \(lastName)"
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            
            // Create initial user profile in Firestore
            try await createInitialUserProfile(uid: user.uid, email: email, firstName: firstName, lastName: lastName)
            
            print("✅ User created successfully: \(email)")
            
        } catch {
            errorMessage = handleAuthError(error)
            print("❌ Sign up error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ User signed in successfully: \(email)")
        } catch {
            errorMessage = handleAuthError(error)
            print("❌ Sign in error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("✅ User signed out successfully")
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            print("❌ Sign out error: \(error)")
        }
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("✅ Password reset email sent to: \(email)")
        } catch {
            errorMessage = handleAuthError(error)
            print("❌ Password reset error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Create Initial User Profile
    private func createInitialUserProfile(uid: String, email: String, firstName: String, lastName: String) async throws {
        let fullName = "\(firstName) \(lastName)"
        let username = "\(firstName.lowercased())\(lastName.lowercased())" // Generate basic username
        
        let userProfile = UserProfile(
            id: uid,
            profilePhotoURL: nil,
            name: fullName,
            username: username,
            year: "", // Will be filled during profile setup
            major: "", // Will be filled during profile setup
            bio: "",
            interests: [],
            clubs: [],
            personalityAnswers: ["", "", "", ""] // Empty personality answers to fill later
        )
        
        let profileData = try userProfile.toDictionary()
        var finalData = profileData
        finalData["createdAt"] = FieldValue.serverTimestamp()
        finalData["updatedAt"] = FieldValue.serverTimestamp()
        finalData["email"] = email // Store email with profile
        
        try await db.collection("users").document(uid).setData(finalData)
        
        // Also create user metadata
        let userMetadata: [String: Any] = [
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "createdAt": Timestamp(),
            "lastActiveAt": Timestamp(),
            "isProfileComplete": false
        ]
        
        try await db.collection("userMetadata").document(uid).setData(userMetadata)
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }
        
        if let authError = error as NSError?, authError.domain == AuthErrorDomain {
            switch AuthErrorCode(rawValue: authError.code) {
            case .emailAlreadyInUse:
                return "This email is already registered. Please sign in instead."
            case .weakPassword:
                return "Password is too weak. Please use at least 6 characters."
            case .invalidEmail:
                return "Please enter a valid email address."
            case .userNotFound:
                return "No account found with this email address."
            case .wrongPassword:
                return "Incorrect password. Please try again."
            case .tooManyRequests:
                return "Too many failed attempts. Please try again later."
            case .networkError:
                return "Network error. Please check your connection."
            default:
                return authError.localizedDescription
            }
        }
        
        return error.localizedDescription
    }
    
    // MARK: - Profile Management
    
    /// Load user profile from Firestore
    func loadUserProfile(uid: String) async throws -> UserProfile? {
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        // Remove Firebase-specific fields that aren't part of UserProfile
        var cleanedData = data
        cleanedData.removeValue(forKey: "createdAt")
        cleanedData.removeValue(forKey: "updatedAt")
        cleanedData.removeValue(forKey: "email")
        
        return try UserProfile.fromDictionary(cleanedData)
    }
    
    /// Save user profile to Firestore
    func saveUserProfile(_ profile: UserProfile) async throws {
        var profileData = try profile.toDictionary()
        profileData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await db.collection("users").document(profile.id).setData(profileData, merge: true)
    }
    
    /// Get current user's profile
    func getCurrentUserProfile() async throws -> UserProfile? {
        guard let uid = user?.uid else { return nil }
        return try await loadUserProfile(uid: uid)
    }
    
    /// Fetch all users for explore feed (excluding current user)
    func fetchAllUsers() async throws -> [UserProfile] {
        print("🔍 Starting to fetch all users...")
        let snapshot = try await db.collection("users").getDocuments()
        let currentUserID = user?.uid ?? ""
        print("📊 Total documents in users collection: \(snapshot.documents.count)")
        print("🚫 Current user ID to exclude: \(currentUserID)")
        
        var allUsers: [UserProfile] = []
        
        for document in snapshot.documents {
            print("📄 Processing document: \(document.documentID)")
            
            // Skip current user
            if document.documentID == currentUserID {
                print("⏭️ Skipping current user: \(document.documentID)")
                continue
            }
            
            let data = document.data()
            print("📋 Raw data for \(document.documentID): \(data.keys)")
            
            // Create UserProfile with flexible field handling - no JSON parsing needed
            let userProfile = UserProfile(
                id: document.documentID, // Use document ID as fallback
                profilePhotoURL: data["profilePhotoURL"] as? String,
                name: data["name"] as? String ?? "Unknown User",
                username: data["username"] as? String ?? "user",
                year: data["year"] as? String ?? "",
                major: data["major"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                interests: data["interests"] as? [String] ?? [],
                clubs: data["clubs"] as? [String] ?? [],
                personalityAnswers: data["personalityAnswers"] as? [String] ?? ["", "", "", ""]
            )
            
            print("✅ Successfully created profile for: \(userProfile.name) (@\(userProfile.username))")
            print("   📝 Major: '\(userProfile.major)' | Year: '\(userProfile.year)' | Bio: '\(userProfile.bio.prefix(50))'")
            
            // Only skip if the user has no meaningful information at all
            if userProfile.name == "Unknown User" && userProfile.major.isEmpty && userProfile.bio.isEmpty && userProfile.interests.isEmpty {
                print("⚠️ Skipping user with no meaningful profile information")
                continue
            }
            
            allUsers.append(userProfile)
        }
        
        print("📱 Final result: \(allUsers.count) users for explore feed")
        for user in allUsers {
            print("👤 User: \(user.name) | Major: \(user.major) | Year: \(user.year)")
        }
        
        return allUsers
    }
    
    /// Create profile for existing user who doesn't have one
    func createProfileForCurrentUser() async throws -> UserProfile? {
        guard let user = user else { return nil }
        
        let displayName = user.displayName ?? ""
        let email = user.email ?? ""
        
        // Split display name into first/last name
        let nameParts = displayName.split(separator: " ")
        let firstName = nameParts.first.map(String.init) ?? ""
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        // Generate username from email or name
        let username = email.split(separator: "@").first?.lowercased() ?? firstName.lowercased()
        
        let newProfile = UserProfile(
            id: user.uid,
            profilePhotoURL: nil,
            name: displayName.isEmpty ? "User" : displayName,
            username: String(username),
            year: "",
            major: "",
            bio: "",
            interests: [],
            clubs: [],
            personalityAnswers: ["", "", "", ""]
        )
        
        // Save to Firebase
        try await saveUserProfile(newProfile)
        
        print("✅ Created new profile for existing user: \(email)")
        return newProfile
    }
}

// MARK: - Custom Auth Errors
enum AuthError: LocalizedError {
    case invalidGmailEmail
    
    var errorDescription: String? {
        switch self {
        case .invalidGmailEmail:
            return "Please use a Gmail address (@gmail.com)"
        }
    }
}

// MARK: - UserProfile Extension
extension UserProfile {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        return dictionary ?? [:]
    }
    
    static func fromDictionary(_ dictionary: [String: Any]) throws -> UserProfile {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: .fragmentsAllowed)
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }
}