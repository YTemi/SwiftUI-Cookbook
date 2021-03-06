//
//  ContentView.swift
//  CombineCoreLocationManagerApp
//
//  Created by giordano scalzo on 31/03/2020.
//  Copyright © 2020 giordano scalzo. All rights reserved.
//

import SwiftUI
import CoreLocation
import Combine

class LocationManager: NSObject {
    enum LocationError: String, Error {
        case notDetermined
        case restricted
        case denied
        case unknown
    }
    
    let statusPublisher = PassthroughSubject<CLAuthorizationStatus, LocationError>()
    let locationPublisher = PassthroughSubject<CLLocation?, Never>()
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func start() {
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            statusPublisher.send(completion: .failure(.notDetermined))
        case .restricted:
            statusPublisher.send(completion: .failure(.restricted))
        case .denied:
            statusPublisher.send(completion: .failure(.denied))
        case .authorizedAlways, .authorizedWhenInUse:
            statusPublisher.send(status)
        @unknown default:
            statusPublisher.send(completion: .failure(.unknown))
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationPublisher.send(location)
    }
}

class LocationViewModel: ObservableObject {
    @Published
    private var status: CLAuthorizationStatus = .notDetermined
    @Published
    private var currentLocation: CLLocation?
    @Published
    var isStartable = true
    @Published
    var errorMessage = ""
    
    private let locationManager = LocationManager()
    
    var thereIsAnError: Bool {
        !errorMessage.isEmpty
    }
    
    var latitude: String {
        currentLocation.latitudeDescription
    }
    
    var longitude: String {
        currentLocation.longitudeDescription
    }
    
    var statusDescription: String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .authorizedAlways:
            return "authorizedAlways"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        @unknown default:
            return "unknown"
        }
    }
    
    func startUpdating() {
        locationManager.start()
        isStartable = false
    }
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    init() {
        locationManager.statusPublisher
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = error.rawValue
                }
            } receiveValue: { self.status = $0}
            .store(in: &cancellableSet)
        
        locationManager.locationPublisher
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates(by: lessThanOneMeter)
            .assign(to: \.currentLocation, on: self)
            .store(in: &cancellableSet)
    }
    
    private func lessThanOneMeter(_ lhs: CLLocation?, _ rhs: CLLocation?) -> Bool {
        if lhs == nil && rhs == nil {
            return true
        }
        guard let lhr = lhs,
            let rhr = rhs else {
                return false
        }
        
        return lhr.distance(from: rhr) < 1
    }
}

extension Optional where Wrapped == CLLocation {
    var latitudeDescription: String {
        guard let self = self else {
            return "-"
        }
        return String(format: "%0.4f", self.coordinate.latitude)
    }
    
    var longitudeDescription: String {
        guard let self = self else {
            return "-"
        }
        return String(format: "%0.4f", self.coordinate.longitude)
    }
}

struct ContentView: View {
    @ObservedObject
    var locationViewModel = LocationViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                if locationViewModel.thereIsAnError {
                    Text("Location Service terminated with error: \(locationViewModel.errorMessage)")
                } else {
                    Text("Status: \(locationViewModel.statusDescription)")
                    HStack {
                        Text("Latitude: \(locationViewModel.latitude)")
                        Text("Longitude: \(locationViewModel.longitude)")
                    }
                }
            }
            .padding(.horizontal, 24)
            
            if locationViewModel.isStartable {
                Button {
                    locationViewModel.startUpdating()
                } label: {
                    Text("Start location updating")
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(5)
                }
            } else {
                /*@START_MENU_TOKEN@*/EmptyView()/*@END_MENU_TOKEN@*/
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
