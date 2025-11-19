import SwiftUI

struct OtherProfileDetailView: View {
    let profile: UserProfile
    var isCurrentUser: Bool = false
    var onEdit: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    AsyncImage(url: URL(string: profile.profilePhotoURL ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image("AppIcon")
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(Circle()).shadow(radius: 6)
                    Text(profile.name).font(.title2).bold()
                    Text("@\(profile.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text([profile.major, profile.year].filter { !$0.isEmpty }.joined(separator: " • "))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity).padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                if !profile.bio.isEmpty {
                    section("About") { Text(profile.bio).foregroundStyle(.secondary) }
                }

                if !profile.interests.isEmpty {
                    section("Interests") {
                        Text(profile.interests.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }
                }

                if !profile.clubs.isEmpty {
                    section("Clubs") {
                        Text(profile.clubs.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Personality Questions Section
                if !profile.personalityAnswers.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    section("Personality") {
                        VStack(alignment: .leading, spacing: 16) {
                            let questions = [
                                "What's your favorite way to spend a weekend?",
                                "Describe yourself in three words.",
                                "What's something you're passionate about?",
                                "What's your ideal study environment?"
                            ]
                            
                            ForEach(0..<min(questions.count, profile.personalityAnswers.count), id: \.self) { index in
                                let answer = profile.personalityAnswers[index].trimmingCharacters(in: .whitespacesAndNewlines)
                                if !answer.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(questions[index])
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        
                                        Text(answer)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                if !profile.personalityAnswers.isEmpty && profile.personalityAnswers.contains(where: { !$0.isEmpty }) {
                    section("Personality") {
                        VStack(alignment: .leading, spacing: 12) {
                            let questions = [
                                "What do you do in your free time?",
                                "What are 3 words to describe yourself?",
                                "What are you passionate about?",
                                "What is your favorite study spot?"
                            ]
                            
                            ForEach(0..<min(profile.personalityAnswers.count, questions.count), id: \.self) { index in
                                if !profile.personalityAnswers[index].isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(questions[index])
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                        
                                        Text(profile.personalityAnswers[index])
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    if index < min(profile.personalityAnswers.count, questions.count) - 1 
                                       && profile.personalityAnswers.indices.contains(index + 1)
                                       && !profile.personalityAnswers[index + 1].isEmpty {
                                        Divider()
                                            .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16).padding(.top, 12)
        }
        .navigationTitle(isCurrentUser ? "My Profile" : profile.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private func tags(_ items: [String]) -> some View {
        // simple chips — replace with your TagView later if you want
        Wrap(items) { tag in
            Text(tag).font(.caption)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color(.systemGray6)).clipShape(Capsule())
        }
    }
}

private struct Wrap<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data; let content: (Data.Element) -> Content
    init(_ items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) { self.items = items; self.content = content }
    var body: some View {
        var w: CGFloat = 0, h: CGFloat = 0
        return GeometryReader { g in
            ZStack(alignment: .topLeading) {
                ForEach(Array(items), id: \.self) { it in
                    content(it)
                        .padding(.trailing, 8).padding(.bottom, 8)
                        .alignmentGuide(.leading) { d in
                            if w + d.width > g.size.width { w = 0; h -= d.height }
                            let r = w; w += d.width; return r
                        }
                        .alignmentGuide(.top) { _ in h }
                }
            }
        }
        .frame(minHeight: 0)
    }
}


