import Observation

@MainActor
protocol PhotoDetailsViewModel: AnyObject, Observable {
    var state: PhotoDetailsViewState { get }

    func send(_ event: PhotoDetailsViewEvent)
}

enum PhotoDetailsViewEvent: Equatable {
    case photographerAttributionTapped
    case photoAttributionTapped
}
