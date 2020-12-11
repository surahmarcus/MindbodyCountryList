import MapKit
import UIKit

class CountryDetailsViewController: UIViewController {
    private struct Province: Decodable {
        enum CodingKeys: String, CodingKey {
                // Map the JSON key "Name" to the Swift property name "name"
                case name = "Name"
                case code = "Code"
                case country = "CountryCode"
        }
        let name: String
        let code: String
        let country: String
    }
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        return mapView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.accessibilityIdentifier = "tableView"
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        self.loadProvinceData()
    })
    
    private var provinces: [Province] = []
    private var countryCode: String = ""
    private var countryName: String = ""
    
    init(countryCode: Int, countryName: String) {
        super.init(nibName: nil, bundle: nil)
        self.countryCode = String(countryCode)
        self.countryName = countryName
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Provinces of \(countryName)"
        
        view.addSubview(tableView)
        view.addSubview(spinnerView)
        
        addConstraints()
        
        loadProvinceData()
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
    
    private func loadProvinceData() {
        getProvinceData(completion: {_ in
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.spinnerView.stopAnimating()
            }
        })
    }
    
    private func getProvinceData(completion: @escaping ([Province]) -> ()) {
        let urlString = "https://connect.mindbodyonline.com/rest/worldregions/country/\(countryCode)/province"
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [self] data, response, error in
                if let data = data {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase // not necessary?
                    do {
                        let provinceResults = try decoder.decode(Array<Province>.self, from: data)
                        self.provinces = provinceResults
                        completion(provinceResults)
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

extension CountryDetailsViewController: UITableViewDelegate {
    
}

extension CountryDetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return provinces.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = provinces[indexPath.row].name
        
        //let countryCode = provinces[indexPath.row].code
        return cell
    }
}
