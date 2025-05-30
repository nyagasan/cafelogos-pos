//
//  DI.swift
//  cafelogos-pos
//
//  Created by ygates on 2023/10/06.
//

import Foundation
import Dependencies
import Connect
import cafelogos_grpc
import SwiftData
import Swifter

private enum DenominationRepositoryKey: DependencyKey {
    @MainActor
    static private(set) var liveValue: any DenominationRepository = {
        let container = ModelContainerFactory.shared
        return DenominationSwiftData(modelContainer: container)
    }()
}
private enum PaymentRepositoryKey: DependencyKey {
    static let liveValue: any PaymentRepository = PaymentRealm()
}
private enum OrderRepositoryKey: DependencyKey {
    static let liveValue: any OrderRepository = OrderRealm()
}
private enum ConfigRepositoryKey: DependencyKey {
    static let liveValue: any ConfigRepository = ConfigRealm()
}

private func getXconfigValue(for key: String, defaultValue: String) -> String {
    guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
        return defaultValue
    }
    if value.isEmpty || value.contains("$(") {
        return defaultValue
    }
    return value
}

private enum GrpcClientKey: DependencyKey {
    static let liveValue: ProtocolClient = {
        let apiProtocol = getXconfigValue(for: "API_PROTOCOL", defaultValue: "http")
        let host = getXconfigValue(for: "API_HOST", defaultValue: "localhost:8080")
        return createClient(hostUrl: "\(apiProtocol)://\(host)")
    }()
    
    // クライアント作成用のヘルパーメソッド
    static func createClient(hostUrl: String) -> ProtocolClient {
        return ProtocolClient(
            httpClient: URLSessionHTTPClient(),
            config: ProtocolClientConfig(
                host: hostUrl,
                networkProtocol: .connect,
                codec: ProtoCodec()
            )
        )
    }
}


private enum ServerProductQueryServiceKey: DependencyKey {
    static var liveValue: any ProductQueryService {
        return ProductQueryServiceServer()
    }
}
private enum ServerDiscountRepositoryKey: DependencyKey {
    static var liveValue: any DiscountRepository {
        return DiscountRepositoryServer()
    }
}
private enum PaymentServerServiceKey: DependencyKey {
    static var liveValue: any PaymentService {
        return PaymentServiceServer()
    }
}
private enum SeatServerRepositoryKey: DependencyKey {
    static var liveValue: any SeatRepository {
        return SeatRepositoryServer()
    }
}
private enum OrderServerServiceKey: DependencyKey {
    static var liveValue: any OrderService {
        return OrderServiceServer()
    }
}
private enum CashierAdapterKey: DependencyKey {
    static let liveValue: any CashierAdapter = StarXCashierAdapter()
}
private enum CustomerDisplayServiceKey: DependencyKey {
    static let liveValue: any CustomerDisplayService = HTTPServerCustomerDisplayService()
}
private enum DrawerTestKey: DependencyKey { // ContainerWithNavBarでドロア解放を行うためのKey
    static let liveValue = DrawerTest()
}

private enum ConfigObserverKey: DependencyKey {
    static let liveValue: any ConfigObserverProtocol = ConfigObserver()
}

private enum TicketRepositoryKey: DependencyKey {
    @MainActor
    static private(set) var liveValue: any TicketRepository = {
        let container = ModelContainerFactory.shared
        return TicketSwiftData(modelContainer: container)
    }()
}

extension DependencyValues {
    var denominationRepository: any DenominationRepository {
        get { self[DenominationRepositoryKey.self] }
        set { self[DenominationRepositoryKey.self] = newValue }
    }
    var paymentRepository: any PaymentRepository {
        get { self[PaymentRepositoryKey.self] }
        set { self[PaymentRepositoryKey.self] = newValue }
    }
    var orderRepository: any OrderRepository {
        get { self[OrderRepositoryKey.self] }
        set { self[OrderRepositoryKey.self] = newValue }
    }
    var configRepository: any ConfigRepository {
        get { self[ConfigRepositoryKey.self] }
        set{ self[ConfigRepositoryKey.self] = newValue }
    }
    var grpcClient: ProtocolClient {
        get { self[GrpcClientKey.self] }
        set { self[GrpcClientKey.self] = newValue }
    }
    var serverProductQS: any ProductQueryService {
        get { self[ServerProductQueryServiceKey.self] }
        set { self[ServerProductQueryServiceKey.self] = newValue }
    }
    var serverDiscountRepository: any DiscountRepository {
        get { self[ServerDiscountRepositoryKey.self] }
        set { self[ServerDiscountRepositoryKey.self] = newValue }
    }
    var serverSeatRepository: any SeatRepository {
        get { self[SeatServerRepositoryKey.self] }
        set { self[SeatServerRepositoryKey.self] = newValue }
    }
    var serverPaymentService: any PaymentService {
        get { self[PaymentServerServiceKey.self] }
        set { self[PaymentServerServiceKey.self] = newValue }
    }
    var serverOrderService: any OrderService {
        get { self[OrderServerServiceKey.self] }
        set { self[OrderServerServiceKey.self] = newValue }
    }
    var cashierAdapter: any CashierAdapter {
        get { self[CashierAdapterKey.self] }
        set { self[CashierAdapterKey.self] = newValue }
    }
    public var customerDisplay: any CustomerDisplayService {
        get {self[CustomerDisplayServiceKey.self] }
        set {self[CustomerDisplayServiceKey.self] = newValue }
    }

    // ContainerWithNavBarでドロア解放を行うために実装
    // NavBar用のFeatureを作ると複雑化して可読性が下がるため、DIして対応
    public var drawerTest: DrawerTest {
        get { self[DrawerTestKey.self] }
        set { self[DrawerTestKey.self] = newValue }
    }
    
    public var configObserver: any ConfigObserverProtocol {
        get { self[ConfigObserverKey.self] }
        set { self[ConfigObserverKey.self] = newValue }
    }
    
    public var ticketRepository: any TicketRepository {
        get { self[TicketRepositoryKey.self] }
        set { self[TicketRepositoryKey.self] = newValue }
    }
    
    // 依存関係を動的に更新するためのヘルパーメソッド
    static func withValues(_ update: (inout DependencyValues) -> Void) {
        var values = DependencyValues()
        update(&values)
        
        // グローバルな依存関係を更新
        withDependencies {
            update(&$0)
        } operation: {
            // 空のオペレーションを実行して依存関係を更新
        }
    }
}
