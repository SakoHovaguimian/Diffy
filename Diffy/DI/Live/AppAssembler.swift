import Foundation

@MainActor
final class AppAssembler {

    let services: ServiceAssembly
    let viewModels: ViewModelAssembly

    init(isPreview: Bool = false) {

        let services = ServiceAssembly(isPreview: isPreview)

        self.services = services
        self.viewModels = ViewModelAssembly(services: services)

    }

}
