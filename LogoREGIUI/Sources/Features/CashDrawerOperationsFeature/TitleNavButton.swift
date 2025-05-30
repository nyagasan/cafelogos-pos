// 遷移先が指定されているボタン
// サブタイトルが付けれる

import SwiftUI

struct TitleNavButton: View {
    var title: String
    var bgColor: Color
    var fgColor: Color

    public init(title: String, bgColor: Color, fgColor: Color) {
        self.title = title
        self.bgColor = bgColor
        self.fgColor = fgColor
    }

    var body: some View {
            VStack(spacing: 0) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .lineLimit(0)
            }
            .foregroundStyle(fgColor)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .center)
            .clipped()
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(bgColor)
            }
            .padding(.bottom)
    }
}

#Preview {
    TitleNavButton(title: "hoge", bgColor: Color.blue, fgColor: Color.white)
}
