import Foundation

@MainActor
final class AppAssembler {

    let services: ServiceAssembly
    let viewModels: ViewModelAssembly

    init(runtime: AppRuntime = .current) {

        let services = ServiceAssembly(runtime: runtime)

        self.services = services
        self.viewModels = ViewModelAssembly(services: services)

    }

}
