import SwiftUI
import PhotosUI

struct ChatView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var viewModel: ChatViewModel
    @State private var showConversationList = false
    @State private var showImageSourcePicker = false
    @State private var showCamera = false
    @State private var showCalculator = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var isInputFocused: Bool

    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = State(wrappedValue: ChatViewModel(context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            messagesArea
            if let image = viewModel.selectedImage {
                imagePreview(image)
            }
            inputBar
        }
        .background(AppTheme.Colors.groupedBackground)
        .sheet(isPresented: $showConversationList) {
            ConversationListView(viewModel: viewModel)
                .presentationDetents([.fraction(0.7)])
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(image: $viewModel.selectedImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showCalculator) {
            if let result = viewModel.recognitionForCalculator {
                NavigationStack {
                    Group {
                        if result.isSingleMaterial {
                            CostCalculatorView(prefillData: result)
                        } else {
                            CostCalculatorViewWithMaterial(prefillData: result)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("关闭") { showCalculator = false }
                                .foregroundStyle(AppTheme.Colors.primary)
                        }
                    }
                }
            }
        }
        .confirmationDialog("选择图片来源", isPresented: $showImageSourcePicker) {
            Button("相机拍照") {
                showCamera = true
            }
            Button("从相册选择") {}
            Button("取消", role: .cancel) {}
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectedImage = image
                }
                selectedPhotoItem = nil
            }
        }
        .onChange(of: viewModel.navigateToCalculator) { _, navigate in
            if navigate {
                showCalculator = true
                viewModel.navigateToCalculator = false
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button {
                viewModel.loadConversations()
                showConversationList = true
            } label: {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .padding(.leading, AppTheme.Spacing.medium)

            Spacer()

            Text("织梦·雅集")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Spacer()

            Button {
                viewModel.createNewConversation()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .padding(.trailing, AppTheme.Spacing.medium)
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(AppTheme.Colors.background)
    }

    // MARK: - Messages

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.small) {
                    if viewModel.messages.isEmpty {
                        emptyStateView
                            .padding(.top, 80)
                    }

                    ForEach(viewModel.messages) { message in
                        if message.isRecognitionCard, let result = message.recognitionResult {
                            RecognitionCardView(result: result) {
                                viewModel.navigateToCalculator(with: result)
                            }
                            .id(message.id)
                        } else {
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }

                    if viewModel.isRecognizing {
                        HStack(spacing: AppTheme.Spacing.xSmall) {
                            ProgressView()
                                .tint(AppTheme.Colors.primary)
                            Text("正在识别...")
                                .font(AppTheme.Typography.caption1)
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                        .padding()
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom_anchor")
                }
                .padding(.vertical, AppTheme.Spacing.small)
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation(AppTheme.Animation.standard) {
                    proxy.scrollTo("bottom_anchor", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.scrollToBottomTrigger) {
                proxy.scrollTo("bottom_anchor", anchor: .bottom)
            }
            .onTapGesture {
                isInputFocused = false
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.Colors.primaryGradient)

            Text("织梦·雅集")
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("发送文字提问，或上传纺织品规格图片\n自动识别参数并填入计算器")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)

            HStack(spacing: AppTheme.Spacing.small) {
                quickActionButton(icon: "camera.fill", text: "拍照识别") {
                    showCamera = true
                }
                quickActionButton(icon: "photo.on.rectangle", text: "选图识别") {
                    showImageSourcePicker = false
                }
            }
            .padding(.top, AppTheme.Spacing.small)
        }
    }

    private func quickActionButton(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xSmall) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.Colors.primary)
                Text(text)
                    .font(AppTheme.Typography.caption1)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .frame(width: 100, height: 70)
            .background(AppTheme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }

    // MARK: - Image Preview

    private func imagePreview(_ image: UIImage) -> some View {
        HStack {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                Button {
                    viewModel.selectedImage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
                .offset(x: 6, y: -6)
            }
            .padding(.leading, AppTheme.Spacing.medium)

            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(AppTheme.Colors.background)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: AppTheme.Spacing.xSmall) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(width: 36, height: 36)
                }

                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    }
                } label: {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(width: 36, height: 36)
                }

                TextField("输入消息...", text: $viewModel.inputText, axis: .vertical)
                    .font(AppTheme.Typography.body)
                    .lineLimit(1...5)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                    .background(AppTheme.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                    .focused($isInputFocused)

                Button {
                    isInputFocused = false
                    viewModel.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            (viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                             && viewModel.selectedImage == nil)
                            ? AnyShapeStyle(AppTheme.Colors.tertiaryText)
                            : AnyShapeStyle(AppTheme.Colors.primaryGradient)
                        )
                }
                .disabled(
                    (viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     && viewModel.selectedImage == nil)
                    || viewModel.isSending
                )
            }
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.xSmall)
            .background(AppTheme.Colors.background)
        }
    }
}
