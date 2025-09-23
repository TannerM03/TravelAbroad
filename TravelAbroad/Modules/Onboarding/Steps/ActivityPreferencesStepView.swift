//
//  ActivityPreferencesStepView.swift
//  TravelAbroad
//

import SwiftUI

struct ActivityPreferencesStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                VStack(spacing: 24) {
                    instructionsSection
                    categoriesSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Activity Preferences")
                .font(.title)
                .fontWeight(.bold)

            Text("Drag activities into categories that match your interests")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var instructionsSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.title3)
                .foregroundColor(.accentColor)

            Text("Tap and hold to drag activities between categories")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.thinMaterial)
        )
    }

    private var categoriesSection: some View {
        VStack(spacing: 16) {
            DropZone(
                title: "Love it!",
                subtitle: "I seek these out",
                color: .green,
                activities: vm.loveItActivities,
                preferenceLevel: .loveIt,
                vm: vm
            )

            DropZone(
                title: "Like it",
                subtitle: "I enjoy these",
                color: .blue,
                activities: vm.likeItActivities,
                preferenceLevel: .likeIt,
                vm: vm
            )

            DropZone(
                title: "Not my fav",
                subtitle: "I'd rather skip",
                color: .gray,
                activities: vm.notMyFavActivities,
                preferenceLevel: .notMyFav,
                vm: vm
            )
        }
    }
}

struct DropZone: View {
    let title: String
    let subtitle: String
    let color: Color
    let activities: [ActivityPreferences.ActivityType]
    let preferenceLevel: ActivityPreferences.PreferenceLevel
    @Bindable var vm: OnboardingViewModel

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(activities.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.2))
                    )
            }

            // Activities container
            if activities.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isTargeted ? color.opacity(0.2) : Color.clear)
                    .stroke(
                        isTargeted ? color : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .frame(height: 60)
                    .overlay(
                        Text("Drop activities here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 8) {
                    ForEach(activities, id: \.self) { activity in
                        SmallActivityCard(
                            activity: activity,
                            color: color,
                            vm: vm
                        )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }

            provider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, _ in
                if let data = data as? Data,
                   let activityName = String(data: data, encoding: .utf8),
                   let activity = ActivityPreferences.ActivityType.allCases.first(where: { $0.rawValue == activityName })
                {
                    DispatchQueue.main.async {
                        vm.moveActivity(activity, to: preferenceLevel)
                    }
                }
            }
            return true
        }
    }
}

struct ActivityCard: View {
    let activity: ActivityPreferences.ActivityType
    @Bindable var vm: OnboardingViewModel
    @State private var dragOffset = CGSize.zero

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: activity.icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(activity.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .scaleEffect(dragOffset == .zero ? 1.0 : 1.05)
        .offset(dragOffset)
        .onDrag {
            NSItemProvider(object: activity.rawValue as NSString)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
        )
    }
}

struct SmallActivityCard: View {
    let activity: ActivityPreferences.ActivityType
    let color: Color
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: activity.icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)

            Text(activity.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
        )
        .onDrag {
            NSItemProvider(object: activity.rawValue as NSString)
        }
    }
}

#Preview {
    ActivityPreferencesStepView(vm: OnboardingViewModel())
}
