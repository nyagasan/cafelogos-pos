import SwiftUI
import ComposableArchitecture

public struct CashDrawerNumericKeyboardView: View {
    public let store: StoreOf<CashDrawerNumericKeyboardFeature>
    
    var rows: [[String]] {
        [
            ["⌫"],
            ["7", "8", "9"],
            ["4", "5", "6"],
            ["1", "2", "3"],
            ["0", "00", "000"]
        ]
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { numericStr in
                        CashDrawerNumericButton(numericStr: numericStr, onAction: {
                            store.send(.onTapNumericButton(numericStr))
                        })
                    }
                }
            }
        }
        .padding(12)
    }
}

#Preview {
    CashDrawerNumericKeyboardView(store: .init(initialState: CashDrawerNumericKeyboardFeature.State()) {
            CashDrawerNumericKeyboardFeature()
    })
}
