import SwiftUI

struct RecognitionCardView: View {
    let result: TextileRecognitionResult
    let onFillCalculator: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.Spacing.xSmall) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.success)

                Text("纺织品参数识别完成")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)

                Spacer()

                confidenceBadge
            }
            .padding(AppTheme.Spacing.medium)

            Divider().padding(.horizontal, AppTheme.Spacing.medium)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                if let box = result.boxNumber {
                    paramRow(label: "筘号", value: box)
                }
                if let width = result.fabricWidth {
                    paramRow(label: "门幅", value: "\(width) cm")
                }
                if let thread = result.threading {
                    paramRow(label: "穿入", value: thread)
                }
                if let density = result.weftDensity {
                    paramRow(label: "纬密", value: density)
                }
                if let shrinkage = result.fabricShrinkage {
                    paramRow(label: "缩率", value: "\(shrinkage)%")
                }

                if !result.materials.isEmpty {
                    Divider().padding(.vertical, AppTheme.Spacing.xxSmall)
                    Text("材料信息 (\(result.materials.count)种)")
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.secondaryText)

                    ForEach(Array(result.materials.enumerated()), id: \.offset) { index, material in
                        materialRow(material, index: index)
                    }
                }

                if let notes = result.notes, !notes.isEmpty {
                    Divider().padding(.vertical, AppTheme.Spacing.xxSmall)
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.info)
                        Text(notes)
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)

            Button(action: onFillCalculator) {
                HStack {
                    Image(systemName: "arrow.right.doc.on.clipboard")
                        .font(.system(size: 14, weight: .medium))
                    Text(result.isSingleMaterial ? "填入单材料计算器" : "填入多材料计算器")
                        .font(AppTheme.Typography.buttonText)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.small)
                .background(AppTheme.Colors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.medium)
        }
        .background(AppTheme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(color: AppTheme.Colors.shadow, radius: 6, x: 0, y: 3)
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private var confidenceBadge: some View {
        let (text, color): (String, Color) = {
            switch result.confidence {
            case "high": return ("高", AppTheme.Colors.success)
            case "medium": return ("中", AppTheme.Colors.warning)
            default: return ("低", AppTheme.Colors.error)
            }
        }()

        return Text("置信度: \(text)")
            .font(AppTheme.Typography.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func paramRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .frame(width: 50, alignment: .leading)
            Text(value)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.primaryText)
        }
    }

    private func materialRow(_ material: RecognizedMaterial, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(material.name ?? "材料\(index + 1)")
                .font(AppTheme.Typography.footnote)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.primary)

            HStack(spacing: AppTheme.Spacing.medium) {
                if let wv = material.warpYarnValue, let wt = material.warpYarnType {
                    Label("经 \(wv) \(wt)", systemImage: "arrow.up.and.down")
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                if let fv = material.weftYarnValue, let ft = material.weftYarnType {
                    Label("纬 \(fv) \(ft)", systemImage: "arrow.left.and.right")
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                if let wp = material.warpYarnPrice {
                    Text("经价 \(wp)")
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
