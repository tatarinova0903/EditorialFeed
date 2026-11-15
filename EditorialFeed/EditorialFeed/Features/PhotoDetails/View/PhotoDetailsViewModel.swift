import Observation

@MainActor
protocol PhotoDetailsViewModel: AnyObject, Observable {
    var state: PhotoDetailsViewState { get }

    func send(_ event: PhotoDetailsViewEvent)
}

enum PhotoDetailsViewEvent: Equatable {
    case closeTapped
    case photographerAttributionTapped
    case photoAttributionTapped
}

enum PhotoDetailsOutput: Equatable {
    case close
}
