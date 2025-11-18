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
        let userProfile = UserProfile(
            id: uid,
            name: fullName,
            major: "", // Will be filled during profile setup
            year: "", // Will be filled during profile setup
            threads: [],
            interests: [],
            clubs: [],
            bio: "",
            imageName: "AppIcon" // Default image
        )
        
        let profileData = try userProfile.toDictionary()
        try await db.collection("users").document(uid).setData(profileData)
        
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