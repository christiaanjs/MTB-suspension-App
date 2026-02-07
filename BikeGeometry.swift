//
//  BikeGeometry.swift
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

struct BikeGeometry: Codable {
    // MARK: - Frame - Primary Inputs
    var bbHeight: Double = 330.0  // mm from ground
    var stack: Double = 625.0  // mm
    var reach: Double = 490.0  // mm
    var headAngle: Double = 64.0  // degrees from horizontal
    var headTubeLength: Double = 80.0  // mm
    var seatAngle: Double = 76.0  // degrees from horizontal
    var bbToPivotX: Double = -80.0  // mm (negative = behind BB)
    var bbToPivotY: Double = 210.0  // mm (above BB)
    
    // MARK: - Fork
    var forkLength: Double = 590.0  // mm (axle to crown)
    var forkOffset: Double = 44.0  // mm (rake)
    
    // MARK: - Suspension
    var totalTravel: Double = 150.0  // mm
    var swingarmLength: Double = 440.0  // mm (pivot to rear axle)
    
    // MARK: - Shock
    var shockFrameMountX: Double = 30.0  // mm from BB
    var shockFrameMountY: Double = 70.0  // mm from BB
    var shockSwingarmMountDistance: Double = 190.0  // mm from pivot (radius)
    var shockStroke: Double = 65.0  // mm
    var shockETE: Double = 210.0  // mm (eye-to-eye at top-out)
    var shockSpringRate: Double = 60.0  // N/mm
    
    // MARK: - Drivetrain
    var chainringTeeth: Int = 32
    var cogTeeth: Int = 28
    var chainringOffsetX: Double = 0.0  // mm from BB center
    var chainringOffsetY: Double = 0.0  // mm from BB center
    
    // MARK: - Idler
    enum IdlerType: String, Codable, CaseIterable {
        case none = "No Idler"
        case frameMounted = "Frame Mounted"
        case swingarmMounted = "Swingarm Mounted"
    }
    var idlerType: IdlerType = .none
    var idlerX: Double = -60.0  // mm from BB
    var idlerY: Double = 160.0  // mm from BB
    var idlerTeeth: Int = 16  // Tooth count
    
    // MARK: - Center of Mass
    var comX: Double = 100.0  // mm from BB (forward)
    var comY: Double = 860.0  // mm from BB (up)
    
    // MARK: - Wheels
    var frontWheelDiameter: Double = 750.0  // mm (29" wheel)
    var rearWheelDiameter: Double = 750.0  // mm (29" wheel)
    var forkTravel: Double = 170.0  // mm
    var forkCompressionPercent: Double = 0.0  // 0-100%
    
    // MARK: - Frame Details
    var seatTubeLength: Double = 320.0  // mm (vertical height)
    
    // MARK: - Computed Properties
    var frontCenter: Double {
        calculateFrontCenter()
    }
    
    var wheelbase: Double {
        // Placeholder - would need to calculate rear axle position at top-out
        frontCenter + swingarmLength
    }
    
    var frontWheelRadius: Double {
        frontWheelDiameter / 2.0
    }
    
    var rearWheelRadius: Double {
        rearWheelDiameter / 2.0
    }
    
    // MARK: - Methods
    
    /// Calculate front center using frame geometry and fork parameters
    private func calculateFrontCenter() -> Double {
        // Convert head angle to radians
        let htaRad = headAngle * .pi / 180.0
        
        // 1. Head tube top is at (reach, stack) relative to BB
        let htTopX = reach
        let htTopY = stack
        
        // 2. Head tube bottom
        let htBottomX = htTopX + headTubeLength * cos(htaRad)
        let htBottomY = htTopY - headTubeLength * sin(htaRad)
        
        // 3. Front axle position
        let axleX = htBottomX + forkLength * cos(htaRad) + forkOffset * sin(htaRad)
        
        // Front center = axle X position (BB is at X=0)
        return axleX
    }
    
    /// Get main pivot position relative to BB
    func getPivotPosition() -> Point2D {
        Point2D(x: bbToPivotX, y: bbToPivotY)
    }
    
    /// Get chainring center position relative to BB
    func getChainringPosition() -> Point2D {
        Point2D(x: chainringOffsetX, y: chainringOffsetY)
    }
    
    /// Get shock frame mount position relative to BB
    func getShockFrameMount() -> Point2D {
        Point2D(x: shockFrameMountX, y: shockFrameMountY)
    }
}

