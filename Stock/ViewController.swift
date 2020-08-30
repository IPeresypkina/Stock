//
//  ViewController.swift
//  Stock
//
//  Created by Ирина Пересыпкина on 8/30/20.
//  Copyright © 2020 Ирина Пересыпкина. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    /// Определяет и  возвращает один компонент пикера
    /// - Parameter pickerView: UIPickerView
    /// - Returns: Int
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /// Возвращает количество элементов в компоненте component, т.е. количество валют для выбора пользователю.
    /// - Parameters:
    ///   - pickerView: UIPickerView
    ///   - component: Int
    /// - Returns: Int
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
    
    ///UI
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyImage: UIImageView!
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestStocks()
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        
        requestQuoteUpdate()
    }
    
    /// Список акционерных компаний
    private var companies = [String: String]()
    
    
    /// Возвращает строку, отображаемую пикером для строки с индексом row
    /// - Parameters:
    ///   - pickerView: UIPickerView
    ///   - row: Int
    ///   - component: Int
    /// - Returns: String optional
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }

    
    /// Обновление для старта приложения по выбранной акции.
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"

        if companies.count != 0 {
            let selectedRaw = self.companyPickerView.selectedRow(inComponent: 0)
            let selectedSymbol = Array(self.companies.values)[selectedRaw]
            requestImage(for: selectedSymbol)
            requestQuote(for: selectedSymbol)
        } else {
            requestImage(for: "AAPL")
            requestQuote(for: "AAPL")
        }
    }
    
    
    /// Отображение пикера при старте
    /// - Parameters:
    ///   - pickerView: UIPickerView
    ///   - row: Int
    ///   - component: Int
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        requestQuoteUpdate()
    }
    
    
    /// Запрос получения общей информации о компании
    /// - Parameter symbol: String Символьное именование компании
    private func requestQuote(for symbol: String) {
        let token = "pk_fc7b67021ff740fead2a925feb18ba4a"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote/?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                    self?.parseQuote(from: data)
            } else {
                self?.showAlert(message: "No internet connection!")
                return
            }
        }
        dataTask.resume()
    }
    
    
    /// Парсер. Получение информации по выбранной пользователем акции
    /// - Parameter data: Data
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else {
                    self.showAlert(message: "A network error has occurred, please use the application later.")
                    return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                      companySymbol: companySymbol,
                                      price: price,
                                      priceChange: priceChange)
            }
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    
    /// Метод для обновления информации об акции на экране
    /// - Parameters:
    ///   - companyName: String
    ///   - companySymbol: String
    ///   - price: Double
    ///   - priceChange: Double
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        
        if priceChange > 0 {
            self.priceChangeLabel.textColor = UIColor.green
        } else if priceChange < 0 {
            self.priceChangeLabel.textColor = UIColor.red
        }
    }
    
    
    /// Запрос получения логотипа компании
    /// - Parameter symbol: String
    private func requestImage(for symbol: String) {
        let token = "pk_fc7b67021ff740fead2a925feb18ba4a"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo/?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                    self?.loadImage(data: data)
            } else {
                self?.showAlert(message: "No internet connection!")
                return
            }
        }
        dataTask.resume()
    }
    
    
    /// Получение и отображение логотипа по выбранной пользователем акции
    /// - Parameter data: Data
    private func loadImage(data: Data){
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let stringURL = json["url"] as? String
                else {
                    self.showAlert(message: "A network error has occurred, please use the application later.")
                    return
                }
            
            DispatchQueue.main.async {
                let url = URL(string: stringURL)
                let data = try? Data(contentsOf: url!)
                
                if let imageData = data {
                    self.companyImage.image = UIImage(data: imageData)
                }
                
            }
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    
    /// Запрос получения списка компаний
    private func requestStocks() {
        let token = "pk_fc7b67021ff740fead2a925feb18ba4a"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/list/mostactive?listLimit=50&token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
                (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                    self?.parseStocks(data: data)
            } else {
                self?.showAlert(message: "No internet connection!")
                return
            }
        }
        dataTask.resume()
    }
    
    
    /// Парсер. Получение информаций по акциям
    /// - Parameter data: Data
    private func parseStocks(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonArray = jsonObject as? [[String: Any]] else {
                showAlert(message: "A network error has occurred, please use the application later.")
                    return
            }
             DispatchQueue.main.async {
                for array in jsonArray {
                    guard let title = array["symbol"] as? String else { return }
                    guard let name = array["companyName"] as? String else { return }
                    self.companies[name] = title
                }
                self.companyPickerView.reloadAllComponents();
            }
            
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    
    /// Проверка подключения к интернету
    /// - Returns: Bool
    func isConnectedToNetwork() -> Bool
    {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
    
    /// Отображение предупреждений
    /// - Parameter message: String
    func showAlert(message: String) {
        if !isConnectedToNetwork() {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Waring", message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: "Close", style: .cancel)
                alert.addAction(action)
                self.present(alert, animated: true)
            }
        } else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet!", preferredStyle: .alert)
                let action = UIAlertAction(title: "Close", style: .cancel)
                alert.addAction(action)
                self.present(alert, animated: true)
            }
        }
    }
}

