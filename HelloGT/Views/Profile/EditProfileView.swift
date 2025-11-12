//
//  EditProfileView.swift
//  HelloGT
//
//  Created by Sanaa Gada on 11/10/25.
// - also do a create profile page if you dont have ur own profiel yet

import SwiftUI

struct EditProfileView: View {
    @Binding var profile: UserProfile

    @Environment(\.dismiss) private var dismiss
    
    @State private var newThread = ""
    @State private var newInterest = ""
    @State private var newClub = ""

    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Name", text: $profile.name)
                TextField("Major", text: $profile.major)
                TextField("Year", text: $profile.year)
            }

            Section(header: Text("Threads")) {
                ForEach(profile.threads, id: \.self) { thread in
                    Text(thread)
                }
                .onDelete { index in
                    profile.threads.remove(atOffsets: index)
                }

                HStack {
                    TextField("Add new thread", text: $newThread)
                    Button("Add") {
                        guard !newThread.isEmpty else { return }
                        profile.threads.append(newThread)
                        newThread = ""
                    }
                }
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

            Section(header: Text("Profile Picture")) {
                // Placeholder - you can add an image picker later
                HStack {
                    Image(profile.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                    Text("Tap to change (coming soon)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    dismiss()
                }
                .fontWeight(.bold)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}
