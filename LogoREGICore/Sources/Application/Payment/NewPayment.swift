//
//  NewPayment.swift
//  cafelogos-pos
//
//  Created by ygates on 2023/10/13.
//

import Foundation
import Dependencies

public struct NewPayment {
    @Dependency(\.serverPaymentService) var paymentService
    @Dependency(\.paymentRepository) var paymentRepo
    
    @Dependency(\.cashierAdapter) var cashierAdapter
    @Dependency(\.configRepository) var configRepo
    
    public init() {}
    
    public func Execute(payment: Payment, postOrder: Order?, externalPaymentType: String?) async -> NewPaymentOutput {
        let config = configRepo.load()

        var receiptItems: [ReceiptItem] = []
        if let order = postOrder {
            receiptItems = generateReceiptItems(order: order)
        }
        print(receiptItems)
        
        // サーバーリクエスト送信前にドロアを開く
        if(config.isUsePrinter) {
            await cashierAdapter.openCacher()
        }
        
        var ticketNumber: String? = nil
        if configRepo.load().isUseTicketNumber {
            let issueTicket = IssueTicket()
            let ticket = await issueTicket.Execute()
            ticketNumber = ticket.displayNumber
        }
        
        let res = await paymentService.postPayment(payment: payment, postOrder: postOrder, externalPaymentType: externalPaymentType, ticketNumber: ticketNumber)
        if res.error == nil {
            paymentRepo.save(payment: payment)
            
            if(config.isUsePrinter) {
                await cashierAdapter.printReceipt(receipt: OrderReceipt(callNumber: res.callNumber ?? ""))
            }
            if(config.isPrintKitchenReceipt) {
                await cashierAdapter.printKitchenReceipt(orderReceipt: OrderReceipt(callNumber: res.callNumber ?? ""), items: receiptItems)
            }
        }
        return NewPaymentOutput(callNumber: res.callNumber ?? "", error: res.error)
    }
    
    private func generateReceiptItems(order: Order) -> [ReceiptItem] {
        var items: [ReceiptItem] = []
        
        for cartItem in order.cart.items {
            let productName = cartItem.productName // 商品名
            let quantity = cartItem.quantity // 個数
            var brewMethod: String? = nil
            let price: Int = Int(cartItem.productPrice)
            
            if let coffeeHowToBrew = cartItem.coffeeHowToBrew {
                // 淹れ方がある場合
                brewMethod = coffeeHowToBrew.name
            }
            // TODO: OtherProductまわりの処理が必要だったら追加する
            
            let receiptItem = ReceiptItem(
                name: productName,
                brewMethod: brewMethod,
                quantity: Int(quantity),
                price: price
            )
            items.append(receiptItem)
        }
        
        return items
    }

}

public struct NewPaymentOutput {
    public let callNumber: String
    public let error: Error?
}
