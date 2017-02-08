import Foundation
struct Constants {
struct NotificationKeys {
    static let SignedIn = "onSignInCompleted"
}

struct Segues {
    static let SignInToFp = "SignInToFP"
    static let FpToSignIn = "FPToSignIn"
    static let SideMenu = "SideMenuViewController"
    static let NewUser = "setUpUser"
    static let Chat = "embededCenterControllerChat"
    static let PokeList = "PokeView"
    static let PokeLists = "PokeListView"
    static let PokeMess = "PokeMess"
    static let PokeMap = "PokeMap"
}

struct MessageFields {
    static let name = "name"
    static let date = "date"
    static let text = "text"
    static let photoUrl = "photoUrl"
    static let imageUrl = "imageUrl"
    static let nameColor = "color"
}

struct users {
    static let color = "hex"
    static var lat = 0.0
    static var lng = 0.0
}
}
