import UIKit

class CountriesViewController: UIViewController {
    private struct Country: Decodable {
        enum CodingKeys: String, CodingKey {
                // Map the JSON key "ID" to the Swift property name "iD"
                case iD = "ID"
                case name = "Name"
                case code = "Code"
        }
        let iD: Int
        let name: String
        let code: String
    }
    
    // Lazy variables are used so that the views are only created if they are needed
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.accessibilityIdentifier = "tableView"
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.addSubview(refreshControl)
        return tableView
    }()
    
    private lazy var spinnerView: UIActivityIndicatorView = {
        let spinnerView = UIActivityIndicatorView(frame: .zero)
        spinnerView.accessibilityIdentifier = "spinnerView"
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        spinnerView.style = .large
        return spinnerView
    }()
    
    private lazy var alertView: UIAlertController = {
        let alertView = UIAlertController(title: "Loading Failure", message: "We are having trouble accessing our country data.", preferredStyle: .alert)
        alertView.addAction(retryAction)
        return alertView
    }()
    
    private lazy var retryAction: UIAlertAction = UIAlertAction(title: "Retry", style: .default, handler: { (action) -> Void in
        print("User tapped the retry button")
        self.loadCountryData()
    })
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshCountryData(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(named: "IconColor")
        return refreshControl
    }()
    
    private var countries: [Country] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Countries"
        
        view.addSubview(tableView)
        view.addSubview(spinnerView)
        
        addConstraints()
        
        loadCountryData()
    }
    
    private func addConstraints() {
        let safeArea = view.layoutMarginsGuide
        tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor).isActive = true
        
        spinnerView.heightAnchor.constraint(equalTo: spinnerView.widthAnchor).isActive = true
        spinnerView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor).isActive = true
        spinnerView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor).isActive = true
    }
    
    @objc private func refreshCountryData(_ sender: Any) {
        loadCountryData()
        refreshControl.endRefreshing()
    }
    
    private func loadCountryData() {
        getCountryData(completion: {_ in
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.spinnerView.stopAnimating()
            }
        })
    }
    
    private func getCountryData(completion: @escaping ([Country]) -> ()) {
        let urlString = "https://connect.mindbodyonline.com/rest/worldregions/country"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [self] data, response, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase // not necessary?
                    do {
                        let countryResults = try decoder.decode(Array<Country>.self, from: data)
                        self.countries = countryResults
                        completion(countryResults)
                    }
                    catch {
                        DispatchQueue.main.async {
                            self.spinnerView.stopAnimating()
                            self.present(alertView, animated: true, completion: nil)
                        }
                    }
                }
            }.resume()
        }
    }
}

extension CountriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCountry = countries[indexPath.row]
        let showCountryDetailsViewController = CountryDetailsViewController(countryCode: selectedCountry.iD, countryName: selectedCountry.name)
        self.navigationController?.pushViewController(showCountryDetailsViewController, animated: true)
        //self.performSegue(withIdentifier: "showCountryDetails", sender: nil)
    }
}

extension CountriesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = countries[indexPath.row].name
        
        let countryCode = countries[indexPath.row].code
        let url = URL(string: "https://www.countryflags.io/\(countryCode)/flat/64.png")
        if let data = try? Data(contentsOf: url!) {
            cell.imageView?.image = UIImage(data: data)
        }
        return cell
    }
}
