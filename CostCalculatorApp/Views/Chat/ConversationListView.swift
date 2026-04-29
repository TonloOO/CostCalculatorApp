import SwiftUI

struct ConversationListView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.groupedBackground.ignoresSafeArea()

                if viewModel.conversations.isEmpty {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                        Text("暂无对话记录")
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                    }
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            Button {
                                viewModel.loadConversation(conversation)
                                dismiss()
                            } label: {
                                HStack(spacing: AppTheme.Spacing.small) {
                                    Image(systemName: "bubble.left")
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppTheme.Colors.primary)
                                        .frame(width: 32, height: 32)
                                        .background(AppTheme.Colors.primary.opacity(0.1))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(conversation.title)
                                            .font(AppTheme.Typography.headline)
                                            .foregroundStyle(AppTheme.Colors.primaryText)
                                            .lineLimit(1)

                                        Text(formatDate(conversation.updatedAt))
                                            .font(AppTheme.Typography.caption1)
                                            .foregroundStyle(AppTheme.Colors.tertiaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(AppTheme.Colors.tertiaryText)
                                }
                                .padding(.vertical, AppTheme.Spacing.xxSmall)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let conversation = viewModel.conversations[index]
                                viewModel.deleteConversation(conversation)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("历史对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.createNewConversation()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.bubble")
                            Text("新对话")
                        }
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.primary)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
