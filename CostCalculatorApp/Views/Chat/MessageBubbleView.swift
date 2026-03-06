import SwiftUI
import MarkdownUI

struct MessageBubbleView: View {
    let message: ChatDisplayMessage

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.xSmall) {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.Colors.primary.opacity(0.12))
                    .clipShape(Circle())
                    .padding(.top, 4)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: AppTheme.Spacing.xxSmall) {
                if let imageData = message.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }

                if !message.text.isEmpty {
                    if message.isUser {
                        Text(message.text)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.vertical, AppTheme.Spacing.small)
                            .background(AppTheme.Colors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                    } else {
                        Markdown(message.text)
                            .markdownTextStyle {
                                FontSize(15)
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.vertical, AppTheme.Spacing.small)
                            .background(AppTheme.Colors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                    }
                }
            }
            .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.secondary)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.Colors.secondary.opacity(0.12))
                    .clipShape(Circle())
                    .padding(.top, 4)
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, AppTheme.Spacing.small)
    }
}
