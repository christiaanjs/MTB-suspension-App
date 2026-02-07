//
//  BikeDesign.swift
//  MTBsuspension App
//
//  Copyright (C) 2026 Patrick Crowe Rishworth
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published
//  by the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>.
//
import Foundation

struct KinematicState: Codable {
    var travelMM: Double
    var rearAxlePosition: Point2D
    var bbPosition: Point2D
    var pivotPosition: Point2D  // Main pivot position
    var swingarmEyePosition: Point2D  // Shock eye position on swingarm
    var frontAxlePosition: Point2D  // Front axle position
    var shockLength: Double
    var leverageRatio: Double
    var antiSquat: Double
    var antiRise: Double
    var pedalKickback: Double
    var chainGrowth: Double
    var totalChainGrowth: Double
    var wheelRate: Double
    var trail: Double  // Mechanical trail (mm)
    var crankAngle: Double  // Crank rotation from top-out (degrees)
    var forkCompression: Double
    var pitchAngleDegrees: Double  // Bike pitch angle (positive = nose down)
    
    init(
        travelMM: Double = 0,
        rearAxlePosition: Point2D = .zero,
        bbPosition: Point2D = .zero,
        pivotPosition: Point2D = .zero,
        swingarmEyePosition: Point2D = .zero,
        frontAxlePosition: Point2D = .zero,
        shockLength: Double = 0,
        leverageRatio: Double = 0,
        antiSquat: Double = 0,
        antiRise: Double = 0,
        pedalKickback: Double = 0,
        chainGrowth: Double = 0,
        totalChainGrowth: Double = 0,
        wheelRate: Double = 0,
        trail: Double = 0,
        crankAngle: Double = 0,
        forkCompression: Double = 0,
        pitchAngleDegrees: Double = 0
    ) {
        self.travelMM = travelMM
        self.rearAxlePosition = rearAxlePosition
        self.bbPosition = bbPosition
        self.pivotPosition = pivotPosition
        self.swingarmEyePosition = swingarmEyePosition
        self.frontAxlePosition = frontAxlePosition
        self.shockLength = shockLength
        self.leverageRatio = leverageRatio
        self.antiSquat = antiSquat
        self.antiRise = antiRise
        self.pedalKickback = pedalKickback
        self.chainGrowth = chainGrowth
        self.totalChainGrowth = totalChainGrowth
        self.wheelRate = wheelRate
        self.trail = trail
        self.crankAngle = crankAngle
        self.forkCompression = forkCompression
        self.pitchAngleDegrees = pitchAngleDegrees
    }
}

struct AnalysisResults: Codable {
    var states: [KinematicState]
    var axlePath: [Point2D]  // Rear axle path
    var frontAxlePath: [Point2D]  // Front axle path
    
    init(states: [KinematicState] = [], axlePath: [Point2D] = [], frontAxlePath: [Point2D] = []) {
        self.states = states
        self.axlePath = axlePath
        self.frontAxlePath = frontAxlePath
    }
}
