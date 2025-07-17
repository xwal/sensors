//
//  ViewController.swift
//  sensors
//
//  Created by Koan-Sin Tan on 6/19/14.
//  Copyright (c) 2014 Koan-Sin Tan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!

    var currentNames: [String] = []
    var voltageNames: [String] = []
    var thermalNames: [String] = []
    var currentValues: [NSNumber] = []
    var voltageValues: [NSNumber] = []
    var thermalValues: [NSNumber] = []

    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        currentNames = currentSensorNames()
        voltageNames = voltageSensorNames()
        thermalNames = thermalSensorNames()

        currentValues = currentSensorValues()
        voltageValues = voltageSensorValues()
        thermalValues = thermalSensorValues()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                refreshValues()
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        timer = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return currentNames.count
        case 1:
            return voltageNames.count
        case 2:
            return thermalNames.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let text: String

        switch indexPath.section {
        case 0:
            let name = currentNames[indexPath.row]
            let number = currentValues[indexPath.row]
            text = String(format: "%@: %.2f", name, number.doubleValue)
        case 1:
            let name = voltageNames[indexPath.row]
            let number = voltageValues[indexPath.row]
            text = String(format: "%@: %.2f", name, number.doubleValue)
        case 2:
            let name = thermalNames[indexPath.row]
            let number = thermalValues[indexPath.row]
            text = String(format: "%@: %.2f", name, number.doubleValue)
        default:
            text = ""
        }

        cell.textLabel?.text = text

        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Current (A)"
        case 1:
            return "Voltage (V)"
        case 2:
            return "Temperature (°C)"
        default:
            return nil
        }
    }

    private func refreshValues() {
        currentValues = currentSensorValues()
        voltageValues = voltageSensorValues()
        thermalValues = thermalSensorValues()
        tableView.reloadData()
    }

    @IBAction func reloadData(_ sender: Any) {
        refreshValues()
    }
}
