import UIKit
import SwiftyJSON
import Firebase

@objc(PokeViewController)
class PokeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    var ref: FIRDatabaseReference!
    
    var shouldShowSearchResults = false
    let searchController = UISearchController(searchResultsController: nil)
    var _refHandle: FIRDatabaseHandle!
    var pokemon: [FIRDataSnapshot]! = []
    var pokemonAr = [Pokemon]()
    var pokemonFinal = [Pokemon]()
    var filteredArray = [Pokemon]()
    var json: JSON = JSON.null
    var pokeNum = 0
    var set = false
    var old: Int? = 0
    var i: Int = 0
    
    struct Pokemon {
    let name: String

    let number: String
    }
    
    @IBAction func pokeDone(_ sender: UIButton) {
        AppState.sharedInstance.number = String(pokeNum)
        performSegue(withIdentifier: Constants.Segues.PokeMess, sender: nil)
    }
    
    @IBOutlet var PokeTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PokeTable.delegate = self
        PokeTable.dataSource = self
        self.PokeTable.register(UITableViewCell.self, forCellReuseIdentifier: "tableViewCell")
        configureDatabase()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
 
        PokeTable.tableHeaderView = searchController.searchBar
        
    }
    
    func fillPokemon() {
        self.ref.child("Pokemon").observeSingleEvent(of: .value, with: { snapshot in
            for rest in snapshot.children.allObjects as! [FIRDataSnapshot] {
            let messager: JSON = JSON(rest.value!)
            
            self.pokemonFinal.append(Pokemon(name: messager["name"].stringValue, number: rest.key))
                }
            print(self.pokemonFinal.count)
        })
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !shouldShowSearchResults {
            shouldShowSearchResults = true
            PokeTable.reloadData()
        }
        
        searchController.searchBar.resignFirstResponder()
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredArray = pokemonFinal.filter { pokemons in
            return pokemons.name.lowercased().contains(searchText.lowercased())
        }
        PokeTable.reloadData()
    }

    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()

        _refHandle = self.ref.child("Pokemon").observe(.childAdded, with: { (snapshot) -> Void in
            self.pokemon.append(snapshot)
            self.PokeTable.insertRows(at: [IndexPath(row: self.pokemon.count-1, section: 0)], with: .automatic)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredArray.count
        }
        else {
            if (pokemon.count == 150) {
                if (set == false) {
                fillPokemon()
                    set = true
                }
            }
        return pokemon.count
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let indexPath = PokeTable.indexPathForSelectedRow
        
        let currentCell = PokeTable.cellForRow(at: indexPath!)! as UITableViewCell
        let name = currentCell.textLabel!.text
        for index in 0...(pokemonFinal.count - 1) {
            if (name == pokemonFinal[index].name) {
                pokeNum = Int(pokemonFinal[index].number)!
            }
        }
        print(currentCell.textLabel!.text!)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath) as UITableViewCell
        let messageSnapshot: FIRDataSnapshot! = pokemon[(indexPath as IndexPath).row]
        
        let message = messageSnapshot.value as! Dictionary<String, String>
        let messager: JSON = JSON(message)

        let name = messager["name"].stringValue
        let number = messageSnapshot.key
        let temp = Pokemon(name: name, number: number)
        
        pokemonAr.append(temp)
        
        if searchController.isActive && searchController.searchBar.text != "" {
            cell.textLabel?.text = filteredArray[indexPath.row].name
            cell.detailTextLabel?.text = filteredArray[indexPath.row].number
            cell.imageView?.image = UIImage(named: filteredArray[indexPath.row].number)
        }
        else {
            cell.textLabel?.text = (pokemonAr[indexPath.row].name)
            cell.detailTextLabel?.text = pokemonAr[indexPath.row].number
            cell.imageView?.image = UIImage(named: pokemonAr[indexPath.row].number)
        }
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.font  = UIFont.systemFont(ofSize: 28.0, weight: UIFontWeightRegular)
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

extension PokeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}


