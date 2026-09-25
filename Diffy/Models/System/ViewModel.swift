import Combine

@MainActor
protocol ViewModel: AnyObject, ObservableObject, Loggable {}
