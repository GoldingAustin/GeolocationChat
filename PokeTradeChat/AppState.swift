import Foundation
import Firebase

class AppState: NSObject {

  static let sharedInstance = AppState()

    var clientAuth: FIRUser?
  var signedIn = false
  var displayName: String!
    var loc: CLLocationCoordinate2D!
    var number: String!
    var cp: String!
    var mess: String!
    var email: String!
    var newUser = true
    var markerSet = false
  var privateUSer: String!
  var photoUrl: URL?
  var locHash: String? = "00000"
  var oldHash: String?
  var locSet = false
  var messages: [FIRDataSnapshot]! = []
  var refHandle: FIRDatabaseHandle!
  var nameColor: String? = "0000ff"
}
