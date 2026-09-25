import Foundation

enum MockBackendCodeFixtures {

    static let serviceLines = MockCodeFixtures.aligned([
        ("import { UserRepo } from '../repositories/userRepo'", "import { UserRepo } from '../repositories/userRepo'"),
        (nil, "import { UserQuery } from '../models/userQuery'"),
        ("", ""),
        ("export class UserService {", "export class UserService {"),
        ("", ""),
        ("    constructor(private userRepo: UserRepo) {}", "    constructor(private userRepo: UserRepo) {}"),
        ("", ""),
        ("    async getUsers() {", "    async getUsers(query: UserQuery) {"),
        ("", ""),
        ("        return this.userRepo.getUsers()", "        const users = await this.fetchUsers(query)"),
        (nil, ""),
        (nil, "        return users"),
        ("", ""),
        ("    }", "    }"),
        ("", ""),
        (nil, "    private async fetchUsers(query: UserQuery) {"),
        (nil, "        return this.userRepo.getUsers(query)"),
        (nil, "    }"),
        (nil, ""),
        ("}", "}")
    ])

    static let modelLines = MockCodeFixtures.aligned([
        (nil, "export interface UserQuery {"),
        (nil, "    search?: string"),
        (nil, "    limit: number"),
        (nil, "    offset: number"),
        (nil, "}")
    ])

}
