//
//  MotionManager.swift
//  Screen Fare
//
//  Real-time step counting using CMPedometer for walking challenges
//

import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    static let shared = MotionManager()

    private let pedometer = CMPedometer()
    @Published var currentSteps: Int = 0
    @Published var isCountingSteps: Bool = false
    @Published var error: MotionError?

    private var startDate: Date?

    private init() {}

    // MARK: - Simulator Detection

    /// Check if running on simulator (pedometer won't work)
    var isRunningOnSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Availability Checking

    /// Check if step counting is available on this device
    var isStepCountingAvailable: Bool {
        return CMPedometer.isStepCountingAvailable()
    }

    /// Check if motion permission has been granted
    var isAuthorized: Bool {
        guard #available(iOS 11.0, *) else {
            // Pre-iOS 11, motion permission is always granted
            return true
        }

        let status = CMPedometer.authorizationStatus()
        return status == .authorized
    }

    /// Check authorization status
    var authorizationStatus: CMAuthorizationStatus {
        if #available(iOS 11.0, *) {
            return CMPedometer.authorizationStatus()
        } else {
            return .authorized
        }
    }

    // MARK: - Step Counting

    /// Start counting steps from zero
    func startCounting() {
        guard isStepCountingAvailable else {
            error = .hardwareUnavailable
            return
        }

        // Check permission status
        if #available(iOS 11.0, *) {
            let status = CMPedometer.authorizationStatus()
            if status == .denied || status == .restricted {
                error = .permissionDenied
                return
            }
        }

        // Stop any existing pedometer session first
        pedometer.stopUpdates()

        // Reset state
        currentSteps = 0
        error = nil
        startDate = Date()
        isCountingSteps = true

        // Start pedometer updates from now
        pedometer.startUpdates(from: startDate!) { [weak self] data, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.error = .pedometerError(error.localizedDescription)
                    self.isCountingSteps = false
                    return
                }

                if let data = data {
                    self.currentSteps = data.numberOfSteps.intValue
                }
            }
        }
    }

    /// Stop counting steps and reset
    func stopCounting() {
        pedometer.stopUpdates()
        isCountingSteps = false
        currentSteps = 0
        startDate = nil
        error = nil
    }

    /// Reset step count to zero without stopping
    func resetCount() {
        stopCounting()
        startCounting()
    }
}

// MARK: - Error Types

enum MotionError: Error, LocalizedError {
    case hardwareUnavailable
    case permissionDenied
    case pedometerError(String)

    var errorDescription: String? {
        switch self {
        case .hardwareUnavailable:
            return "Step counting is not available on this device"
        case .permissionDenied:
            return "Motion permission is required for walking challenges"
        case .pedometerError(let message):
            return message
        }
    }
}
