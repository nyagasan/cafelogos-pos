import Foundation
import ComposableArchitecture
import LogoREGICore

@Reducer
public struct ProductStackFeature {
    @Reducer(state: .equatable)
    public enum Destination {
        case chooseCoffeeBrew(ChooseCoffeeBrewSheetFeature)
    }
    
    @ObservableState
    public struct State: Equatable {
        var selectProduct: ProductDto? = nil
        
        var productCatalog: [ProductCatalogDto] = []
        
        @Presents var destination: Destination.State?
    }
    
    public enum Action {
        case onTapProduct(ProductDto)
        case destination(PresentationAction<Destination.Action>)
        
        case fetch
        case fetched(Result<[ProductCatalogDto], Error>)
        
        case delegate(Delegate)
        
        public enum Delegate {
            case onAddItem(ProductDto, CoffeeHowToBrewDto?)
            case onConnectionError(Int)
            case onServerConnectionChanged(Bool)
        }
    }
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .fetch:
                return .run { send in
                    let config = GetConfig().Execute()

                    if config.isUseProductMock {
                        // モックサービスを使用
                        await send(
                            .fetched(
                                Result { await ProductQueryServiceMock().fetchProductCategoriesWithProducts() }
                            )
                        )
                    } else {
                        // APIサービスを使用
                        await send(
                            .fetched(
                                Result { await GetCategoriesWithProduct().Execute() }
                            )
                        )
                    }
                }
            case let .fetched(.success(productCatalog)):
                if productCatalog.isEmpty {
                    // FIXME: GetCategoriesWithProduct().Execute() がResult型を返さず、全てSuccessを返すためSuccessの中でハンドリング
                    // 正常にfetchできない場合は空配列が返ってくるためisEmptyで判断
                    return .send(.delegate(.onConnectionError(-1)))
                }
                // サーバー接続状態を更新
                state.productCatalog = productCatalog
                return .send(.delegate(.onServerConnectionChanged(true)))
            case let .onTapProduct(product):
                if(product.productType == ProductType.coffee) {
                    if(product.coffeeHowToBrews?.count == 1) {
                        return .send(.delegate(.onAddItem(
                            product,
                            product.coffeeHowToBrews![0]
                        )))
                    } else {
                        state.selectProduct = product
                        state.destination = .chooseCoffeeBrew(ChooseCoffeeBrewSheetFeature.State(selectProduct: product))
                    }
                } else {
                    return .send(.delegate(.onAddItem(product, nil)))
                }
                return .none
            case .destination(.presented(.chooseCoffeeBrew(.chooseOptionSheetAction(.delegate(.close))))):
                state.destination = nil
                return .none
            case let .destination(.presented(.chooseCoffeeBrew(.delegate(.onTapCoffeeBrew(product, coffeeBrew))))):
                state.destination = nil
                return .send(.delegate(.onAddItem(
                    product,
                    coffeeBrew
                )))
            case .delegate:
                return .none
            default:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
