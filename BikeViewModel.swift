//
//  BikeViewModel.swift
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
import Combine
import SwiftUI

class BikeViewModel: ObservableObject {
    @Published var geometry: BikeGeometry = BikeGeometry()
    @Published var bikeName: String = "Custom Build"
    @Published var analysisResults: AnalysisResults = AnalysisResults()
    @Published var isCalculating: Bool = false
    @Published var currentTravelMM: Double = 0  // Rear shock stroke
    @Published var currentForkStroke: Double = 0  // Fork stroke
    @Published var isAnimating: Bool = false
    @Published var animationSpeed: Double = 1.0
    @Published var slidersLinked: Bool = true  // Link shock and fork sliders
    @Published var selectedGraph: GraphType = .leverageRatio
    
    enum GraphType: String, CaseIterable {
        case leverageRatio = "Leverage Ratio"
        case antiSquat = "Anti-Squat"
        case antiRise = "Anti-Rise"
        case pedalKickback = "Pedal Kickback"
        case axlePath = "Wheel Path"
        case chainGrowth = "Chain Growth"
        case wheelRate = "Wheel Rate"
        case trail = "Trail"
        case pitchAngle = "Pitch Angle"
    }
    
    private var calculationTask: Task<Void, Never>?
    private var animationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Track previous eye position to prevent switching mid-travel
    private var previousEyePosition: Point2D? = nil
    
    init() {
        // Initialize with default bike
        // Auto-calculate when geometry changes
        $geometry
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.calculateKinematics()
            }
            .store(in: &cancellables)
        
        // Initial calculation
        calculateKinematics()
    }
    
    // MARK: - Save/Load
    
    func saveToFile(url: URL) throws {
        let design = BikeDesign(name: bikeName, geometry: geometry)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(design)
        try data.write(to: url)
    }
    
    func loadFromFile(url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let design = try decoder.decode(BikeDesign.self, from: data)
        
        self.bikeName = design.name
        self.geometry = design.geometry
        self.calculateKinematics()
    }
    
    // MARK: - Calculation
    
    func calculateKinematics() {
        // Cancel any existing calculation
        calculationTask?.cancel()
        
        calculationTask = Task {
            await performCalculation()
        }
    }
    
    @MainActor
    private func performCalculation() async {
        isCalculating = true
        defer { isCalculating = false }
        
        // Run calculation on background thread
        let results = await Task.detached(priority: .userInitiated) { [geometry] in
            BikeViewModel.runKinematicAnalysis(geometry: geometry)
        }.value
        
        // Update results on main thread
        self.analysisResults = results
        self.currentTravelMM = 0
        self.currentForkStroke = 0
    }
    
    private static func runKinematicAnalysis(geometry: BikeGeometry) -> AnalysisResults {
        var states: [KinematicState] = []
        var axlePath: [Point2D] = []  // Rear axle path relative to BB
        var frontAxlePath: [Point2D] = []  // Front axle path relative to BB
        
        // Calculate rigid triangle dimensions once at top-out
        let rigidTriangle = establishRigidTriangle(geometry: geometry)
        
        // Step through shock stroke (0 to max), not wheel travel
        let stepSize = 0.5  // mm - finer steps for smoother graphs
        let strokeSteps = Int(geometry.shockStroke / stepSize) + 1
        
        for step in 0..<strokeSteps {
            let shockStroke = Double(step) * stepSize  // mm of shock compression
            
            // Calculate proportional fork compression (both compress in unison)
            let travelRatio = shockStroke / geometry.shockStroke
            let proportionalForkStroke = travelRatio * geometry.forkTravel
            
            var state = BikeViewModel.calculateStateAtShockStroke(
                shockStroke: shockStroke, 
                geometry: geometry, 
                rigidTriangle: rigidTriangle
            )
            
            // Update fork compression
            state.forkCompression = proportionalForkStroke
            
            // Recalculate front axle position with proportional fork compression
            let htaRad = geometry.headAngle * .pi / 180.0
            let effectiveForkLength = geometry.forkLength - proportionalForkStroke
            
            let frontAxlePos = Point2D(
                x: state.bbPosition.x + geometry.reach + geometry.headTubeLength * cos(htaRad) + effectiveForkLength * cos(htaRad) + geometry.forkOffset * sin(htaRad),
                y: state.bbPosition.y + geometry.stack - geometry.headTubeLength * sin(htaRad) - effectiveForkLength * sin(htaRad) + geometry.forkOffset * cos(htaRad)
            )
            
            state.frontAxlePosition = frontAxlePos
            
            // Recalculate pitch with updated front axle
            let rearCenter = state.rearAxlePosition
            let frontCenter = frontAxlePos
            
            let dx = frontCenter.x - rearCenter.x
            let dy = frontCenter.y - rearCenter.y
            let centerDist = sqrt(dx * dx + dy * dy)
            
            let centerAngle = atan2(dy, dx)
            let radiusDiff = geometry.frontWheelRadius - geometry.rearWheelRadius
            let angleOffset = asin(radiusDiff / centerDist)
            let tangentAngle = centerAngle - angleOffset
            
            state.pitchAngleDegrees = tangentAngle * 180.0 / .pi
            
            // Recalculate AS and AR with updated front axle position - MEASURE from visual geometry
            state.antiSquat = calculateVisualAntiSquat(state: state, geometry: geometry)
            state.antiRise = calculateVisualAntiRise(state: state, geometry: geometry)
            
            states.append(state)
            
            // Store wheel positions relative to BB
            let rearRelativeToBB = Point2D(
                x: state.rearAxlePosition.x - state.bbPosition.x,
                y: state.rearAxlePosition.y - state.bbPosition.y
            )
            let frontRelativeToBB = Point2D(
                x: state.frontAxlePosition.x - state.bbPosition.x,
                y: state.frontAxlePosition.y - state.bbPosition.y
            )
            
            axlePath.append(rearRelativeToBB)
            frontAxlePath.append(frontRelativeToBB)
        }
        
        return AnalysisResults(states: states, axlePath: axlePath, frontAxlePath: frontAxlePath)
    }
    
    // Establish rigid triangle at top-out (shock fully extended at shockETE)
    // All input measurements are for this configuration
    private static func establishRigidTriangle(geometry: BikeGeometry) -> (pivotToEye: Double, pivotToAxle: Double, eyeToAxle: Double, correctEyeIndex: Int, axleAngleIsPositive: Bool) {
        // At top-out: BB is at bbHeight, shock is at shockETE
        let pivot = Point2D(x: geometry.bbToPivotX, y: geometry.bbHeight + geometry.bbToPivotY)
        let frameMount = Point2D(x: geometry.shockFrameMountX, y: geometry.bbHeight + geometry.shockFrameMountY)
        
        // Find swingarm eye: circle-circle intersection
        let eyeCandidates = circleCircleIntersection(
            center1: pivot,
            radius1: geometry.shockSwingarmMountDistance,
            center2: frameMount,
            radius2: geometry.shockETE
        )
        
        // Guard against invalid geometry
        guard eyeCandidates.count == 2 else {
            return (geometry.shockSwingarmMountDistance, geometry.swingarmLength, geometry.swingarmLength, 0, true)
        }
        
        // Choose eye with LARGEST X value (most forward) - this determines triangle orientation
        let correctEyeIndex = eyeCandidates[0].x > eyeCandidates[1].x ? 0 : 1
        let chosenEye = eyeCandidates[correctEyeIndex]
        
        // Find axle: swingarmLength from pivot, on ground (Y = wheelRadius)
        let verticalDist = geometry.rearWheelRadius - pivot.y
        
        // Validate geometry - swingarm must be long enough to reach ground
        let horizontalDistSquared = geometry.swingarmLength * geometry.swingarmLength - verticalDist * verticalDist
        guard horizontalDistSquared >= 0 else {
            // Invalid geometry - return safe defaults
            return (geometry.shockSwingarmMountDistance, geometry.swingarmLength, geometry.swingarmLength, 0, true)
        }
        
        let horizontalDist = sqrt(horizontalDistSquared)
        
        let axle1 = Point2D(x: pivot.x + horizontalDist, y: geometry.rearWheelRadius)
        let axle2 = Point2D(x: pivot.x - horizontalDist, y: geometry.rearWheelRadius)
        
        // Choose axle behind pivot (more negative X, i.e., minimum X)
        let axle = axle1.x < axle2.x ? axle1 : axle2
        
        // Calculate three side lengths - these are FIXED for the rigid triangle
        let pivotToEyeDist = distance(pivot, chosenEye)
        let pivotToAxleDist = distance(pivot, axle)
        let eyeToAxleDist = distance(chosenEye, axle)
        
        // Determine which angle sign to use (+ or -) from pivot-eye line
        // Calculate using law of cosines what the angle should be
        let cosAngle = (pivotToEyeDist * pivotToEyeDist + pivotToAxleDist * pivotToAxleDist - eyeToAxleDist * eyeToAxleDist) / 
                       (2 * pivotToEyeDist * pivotToAxleDist)
        let angleAtPivot = acos(cosAngle)
        
        let pivotToEyeAngle = angle(from: pivot, to: chosenEye)
        let pivotToAxleAngle = angle(from: pivot, to: axle)
        
        // Determine if we need to ADD or SUBTRACT the angle
        // Check which one matches the actual axle position
        let testAnglePlus = pivotToEyeAngle + angleAtPivot
        let testAngleMinus = pivotToEyeAngle - angleAtPivot
        
        let testAxlePlus = Point2D(
            x: pivot.x + pivotToAxleDist * cos(testAnglePlus),
            y: pivot.y + pivotToAxleDist * sin(testAnglePlus)
        )
        let testAxleMinus = Point2D(
            x: pivot.x + pivotToAxleDist * cos(testAngleMinus),
            y: pivot.y + pivotToAxleDist * sin(testAngleMinus)
        )
        
        let distPlus = distance(testAxlePlus, axle)
        let distMinus = distance(testAxleMinus, axle)
        
        let axleAngleIsPositive = distPlus < distMinus  // true = use +angle, false = use -angle
        
        print("=== RIGID TRIANGLE ESTABLISHED AT TOP-OUT ===")
        print("Triangle sides: pivot->eye=\(pivotToEyeDist), eye->axle=\(eyeToAxleDist)")
        print("Using eye candidate index: \(correctEyeIndex) (eye at X=\(String(format: "%.1f", chosenEye.x)))")
        print("Axle angle: \(axleAngleIsPositive ? "POSITIVE" : "NEGATIVE") from pivot-eye line")
        print("==============================================\n")
        
        return (pivotToEyeDist, pivotToAxleDist, eyeToAxleDist, correctEyeIndex, axleAngleIsPositive)
    }
    
    private static func calculateStateAtShockStroke(
        shockStroke: Double, 
        geometry: BikeGeometry, 
        rigidTriangle: (pivotToEye: Double, pivotToAxle: Double, eyeToAxle: Double, correctEyeIndex: Int, axleAngleIsPositive: Bool)
    ) -> KinematicState {
        let rearWheelRadius = geometry.rearWheelRadius
        let frontWheelRadius = geometry.frontWheelRadius
        
        // Use the pre-calculated rigid triangle dimensions
        let eyeToAxleDistance = rigidTriangle.eyeToAxle
        
        // Current shock length
        let currentShockLength = geometry.shockETE - shockStroke
        
        // Start with BB at design height (nominal position)
        let pivot = Point2D(x: geometry.bbToPivotX, y: geometry.bbHeight + geometry.bbToPivotY)
        let frameMount = Point2D(x: geometry.shockFrameMountX, y: geometry.bbHeight + geometry.shockFrameMountY)
        
        // Find swingarm eye at this shock length
        let eyeCandidates = circleCircleIntersection(
            center1: pivot,
            radius1: geometry.shockSwingarmMountDistance,
            center2: frameMount,
            radius2: currentShockLength
        )
        
        guard !eyeCandidates.isEmpty else {
            return KinematicState(
                travelMM: 0,
                rearAxlePosition: Point2D.zero,
                bbPosition: Point2D(x: 0, y: geometry.bbHeight),
                pivotPosition: Point2D(x: geometry.bbToPivotX, y: geometry.bbHeight + geometry.bbToPivotY),
                frontAxlePosition: Point2D.zero
            )
        }
        
        // CRITICAL: Always use the same eye candidate index determined at top-out
        // This locks in the triangle orientation and prevents flipping
        let chosenEye = eyeCandidates[rigidTriangle.correctEyeIndex]
        
        print("[\(String(format: "%.0f", shockStroke))mm] Eye0: X=\(String(format: "%.1f", eyeCandidates[0].x)) | Eye1: X=\(String(format: "%.1f", eyeCandidates[1].x)) | Using: Eye\(rigidTriangle.correctEyeIndex) X=\(String(format: "%.1f", chosenEye.x))")
        
        // Find axle using rigid triangle constraint
        // We know: pivot position, eye position, all three side lengths
        let pivotToEyeDist = distance(pivot, chosenEye)
        let pivotToAxleDist = geometry.swingarmLength
        
        // Law of cosines: angle at pivot in the triangle
        let cosAngle = (pivotToEyeDist * pivotToEyeDist + pivotToAxleDist * pivotToAxleDist - eyeToAxleDistance * eyeToAxleDistance) / 
                       (2 * pivotToEyeDist * pivotToAxleDist)
        let angleAtPivot = acos(cosAngle)
        
        let pivotToEyeAngle = angle(from: pivot, to: chosenEye)
        
        // Use the rigid triangle orientation to pick the correct axle
        // No tracking or selection needed - the orientation is fixed throughout travel!
        let axleAngle = rigidTriangle.axleAngleIsPositive ? 
            (pivotToEyeAngle + angleAtPivot) :  // Positive: add angle
            (pivotToEyeAngle - angleAtPivot)    // Negative: subtract angle
        
        let nominalAxle = Point2D(
            x: pivot.x + pivotToAxleDist * cos(axleAngle),
            y: pivot.y + pivotToAxleDist * sin(axleAngle)
        )
        
        // Adjust entire frame DOWN so rear axle is on ground
        let groundOffset = nominalAxle.y - rearWheelRadius
        let bbY = geometry.bbHeight - groundOffset
        
        // Final positions (no pitch adjustment)
        var rearAxlePos = Point2D(x: nominalAxle.x, y: rearWheelRadius)
        var bbPos = Point2D(x: 0, y: bbY)
        var finalPivotPos = Point2D(x: geometry.bbToPivotX, y: pivot.y - groundOffset)
        var finalSwingarmEye = Point2D(x: chosenEye.x, y: chosenEye.y - groundOffset)
        var finalFrameMount = Point2D(x: geometry.shockFrameMountX, y: bbY + geometry.shockFrameMountY)
        
        // Calculate front wheel position (using current fork compression)
        let htaRad = geometry.headAngle * .pi / 180.0
        let frontAxlePos = Point2D(
            x: bbPos.x + geometry.reach + geometry.headTubeLength * cos(htaRad) + geometry.forkLength * cos(htaRad) + geometry.forkOffset * sin(htaRad),
            y: bbPos.y + geometry.stack - geometry.headTubeLength * sin(htaRad) - geometry.forkLength * sin(htaRad) + geometry.forkOffset * cos(htaRad)
        )
        
        // Calculate pitch angle (but don't apply it - that's for display only)
        let dx = frontAxlePos.x - rearAxlePos.x
        let dy = frontAxlePos.y - rearAxlePos.y
        let centerDist = sqrt(dx * dx + dy * dy)
        
        let centerAngle = atan2(dy, dx)
        let radiusDiff = frontWheelRadius - rearWheelRadius
        let angleOffset = asin(radiusDiff / centerDist)
        let tangentAngle = centerAngle - angleOffset
        let pitchAngleDegrees = tangentAngle * 180.0 / .pi
        
        // Calculate top-out axle X for chain growth reference
        let topOutPivot = Point2D(x: geometry.bbToPivotX, y: geometry.bbHeight + geometry.bbToPivotY)
        let topOutVertDist = rearWheelRadius - topOutPivot.y
        let topOutHorizDistSquared = geometry.swingarmLength * geometry.swingarmLength - topOutVertDist * topOutVertDist
        
        // Validate geometry
        guard topOutHorizDistSquared >= 0 else {
            // Return a default state for invalid geometry
            return KinematicState(
                travelMM: 0,
                rearAxlePosition: Point2D(x: 0, y: rearWheelRadius),
                bbPosition: Point2D(x: 0, y: geometry.bbHeight),
                pivotPosition: Point2D(x: geometry.bbToPivotX, y: geometry.bbHeight + geometry.bbToPivotY),
                swingarmEyePosition: Point2D(x: 0, y: 0),
                frontAxlePosition: Point2D(x: 500, y: frontWheelRadius),
                shockLength: geometry.shockETE,
                leverageRatio: 2.5,
                antiSquat: 100.0,
                antiRise: 0.0,
                pedalKickback: 0.0,
                chainGrowth: 0.0,
                totalChainGrowth: 0.0,
                wheelRate: 0.0,
                trail: geometry.forkOffset,
                crankAngle: 0.0,
                forkCompression: 0.0,
                pitchAngleDegrees: 0.0
            )
        }
        
        let topOutHorizDist = sqrt(topOutHorizDistSquared)
        let initialAxleX = topOutPivot.x - topOutHorizDist  // Behind pivot
        let initialAxleY = rearWheelRadius
        
        // Calculate wheel travel
        let wheelTravel = abs(geometry.bbHeight - bbY)
        
        // Calculate shock length with adjusted frame position
        let shockLength = distance(finalFrameMount, finalSwingarmEye)
        
        // Fork compression calculation (should be minimal after pitch adjustment)
        let forkCompressionNeeded = frontAxlePos.y - frontWheelRadius
        let forkCompression = max(0, min(forkCompressionNeeded, geometry.forkTravel))
        
        // Calculate leverage ratio (approximation based on shock stroke)
        // Leverage = wheel travel change / shock travel change
        let leverageRatio = 2.5  // Simplified constant for now to avoid recursion
        
        // Chain calculations - must account for full chain path including idler
        let chainringPos = Point2D(x: bbPos.x + geometry.chainringOffsetX, y: bbPos.y + geometry.chainringOffsetY)
        let cogPos = rearAxlePos
        let chainringRadius = sprocketRadius(teeth: geometry.chainringTeeth)
        let cogRadius = sprocketRadius(teeth: geometry.cogTeeth)
        
        // Calculate total chain length accounting for idler configuration
        // We track both tension (upper) path and total chain path:
        // - Tension path: used for pedal kickback calculation
        // - Total path: used for derailleur capacity assessment
        let tensionChainLength: Double
        let topOutTensionLength: Double
        let lowerReturnLength: Double
        let topOutLowerReturnLength: Double
        
        if geometry.idlerType == .none {
            // No idler: simple chainring to cog
            // Tension path (upper): chainring → cog
            tensionChainLength = calculateChainLength(
                from: chainringPos,
                to: cogPos,
                chainringRadius: chainringRadius,
                cogRadius: cogRadius
            )
            
            // Lower return path: cog → chainring (same calculation, just conceptually returning)
            lowerReturnLength = tensionChainLength
            
            let topOutChainringPos = Point2D(x: geometry.chainringOffsetX, y: geometry.bbHeight + geometry.chainringOffsetY)
            let topOutCogPos = Point2D(x: initialAxleX, y: rearWheelRadius)
            topOutTensionLength = calculateChainLength(
                from: topOutChainringPos,
                to: topOutCogPos,
                chainringRadius: chainringRadius,
                cogRadius: cogRadius
            )
            topOutLowerReturnLength = topOutTensionLength
        } else {
            let idlerRadius = sprocketRadius(teeth: geometry.idlerTeeth)
            
            if geometry.idlerType == .frameMounted {
                // Frame-mounted idler: chainring → idler → cog (tension path)
                let idlerPos = Point2D(x: bbPos.x + geometry.idlerX, y: bbPos.y + geometry.idlerY)
                
                // Tension path (upper)
                let segment1 = calculateChainLength(
                    from: chainringPos,
                    to: idlerPos,
                    chainringRadius: chainringRadius,
                    cogRadius: idlerRadius
                )
                let segment2 = calculateChainLength(
                    from: idlerPos,
                    to: cogPos,
                    chainringRadius: idlerRadius,
                    cogRadius: cogRadius
                )
                tensionChainLength = segment1 + segment2
                
                // Lower return path: cog → chainring direct (no idler on return)
                lowerReturnLength = calculateChainLength(
                    from: cogPos,
                    to: chainringPos,
                    chainringRadius: cogRadius,
                    cogRadius: chainringRadius
                )
                
                // Top-out position (idler is frame-mounted so stays at same BB-relative position)
                let topOutChainringPos = Point2D(x: geometry.chainringOffsetX, y: geometry.bbHeight + geometry.chainringOffsetY)
                let topOutIdlerPos = Point2D(x: geometry.idlerX, y: geometry.bbHeight + geometry.idlerY)
                let topOutCogPos = Point2D(x: initialAxleX, y: rearWheelRadius)
                
                let topOutSegment1 = calculateChainLength(
                    from: topOutChainringPos,
                    to: topOutIdlerPos,
                    chainringRadius: chainringRadius,
                    cogRadius: idlerRadius
                )
                let topOutSegment2 = calculateChainLength(
                    from: topOutIdlerPos,
                    to: topOutCogPos,
                    chainringRadius: idlerRadius,
                    cogRadius: cogRadius
                )
                topOutTensionLength = topOutSegment1 + topOutSegment2
                
                topOutLowerReturnLength = calculateChainLength(
                    from: topOutCogPos,
                    to: topOutChainringPos,
                    chainringRadius: cogRadius,
                    cogRadius: chainringRadius
                )
            } else {
                // Swingarm-mounted idler: chainring → idler → cog (tension path)
                // Calculate idler position (rotates with swingarm)
                let topOutIdlerX = geometry.idlerX - geometry.bbToPivotX
                let topOutIdlerY = (geometry.bbHeight + geometry.idlerY) - (geometry.bbHeight + geometry.bbToPivotY)
                
                let topOutPivot = Point2D(x: geometry.bbToPivotX, y: geometry.bbHeight + geometry.bbToPivotY)
                let topOutVertDist = geometry.rearWheelRadius - topOutPivot.y
                let topOutHorizDistSquared = geometry.swingarmLength * geometry.swingarmLength - topOutVertDist * topOutVertDist
                
                if topOutHorizDistSquared >= 0 {
                    let topOutHorizDist = sqrt(topOutHorizDistSquared)
                    let topOutAxle = Point2D(x: topOutPivot.x - topOutHorizDist, y: geometry.rearWheelRadius)
                    let topOutSwingarmAngle = atan2(topOutAxle.y - topOutPivot.y, topOutAxle.x - topOutPivot.x)
                    
                    let currentSwingarmAngle = atan2(rearAxlePos.y - finalPivotPos.y, rearAxlePos.x - finalPivotPos.x)
                    let rotationAngle = currentSwingarmAngle - topOutSwingarmAngle
                    
                    let rotatedOffsetX = topOutIdlerX * cos(rotationAngle) - topOutIdlerY * sin(rotationAngle)
                    let rotatedOffsetY = topOutIdlerX * sin(rotationAngle) + topOutIdlerY * cos(rotationAngle)
                    
                    let idlerPos = Point2D(
                        x: finalPivotPos.x + rotatedOffsetX,
                        y: finalPivotPos.y + rotatedOffsetY
                    )
                    
                    // Tension path (upper): chainring → idler → cog
                    let segment1 = calculateChainLength(
                        from: chainringPos,
                        to: idlerPos,
                        chainringRadius: chainringRadius,
                        cogRadius: idlerRadius
                    )
                    let segment2 = calculateChainLength(
                        from: idlerPos,
                        to: cogPos,
                        chainringRadius: idlerRadius,
                        cogRadius: cogRadius
                    )
                    tensionChainLength = segment1 + segment2
                    
                    // Lower return path: cog → chainring direct (no idler on return)
                    lowerReturnLength = calculateChainLength(
                        from: cogPos,
                        to: chainringPos,
                        chainringRadius: cogRadius,
                        cogRadius: chainringRadius
                    )
                    
                    // Top-out idler position
                    let topOutIdlerPos = Point2D(
                        x: topOutPivot.x + topOutIdlerX,
                        y: topOutPivot.y + topOutIdlerY
                    )
                    let topOutChainringPos = Point2D(x: geometry.chainringOffsetX, y: geometry.bbHeight + geometry.chainringOffsetY)
                    let topOutCogPos = Point2D(x: initialAxleX, y: rearWheelRadius)
                    
                    let topOutSegment1 = calculateChainLength(
                        from: topOutChainringPos,
                        to: topOutIdlerPos,
                        chainringRadius: chainringRadius,
                        cogRadius: idlerRadius
                    )
                    let topOutSegment2 = calculateChainLength(
                        from: topOutIdlerPos,
                        to: topOutCogPos,
                        chainringRadius: idlerRadius,
                        cogRadius: cogRadius
                    )
                    topOutTensionLength = topOutSegment1 + topOutSegment2
                    
                    topOutLowerReturnLength = calculateChainLength(
                        from: topOutCogPos,
                        to: topOutChainringPos,
                        chainringRadius: cogRadius,
                        cogRadius: chainringRadius
                    )
                } else {
                    // Fallback for invalid geometry
                    tensionChainLength = calculateChainLength(
                        from: chainringPos,
                        to: cogPos,
                        chainringRadius: chainringRadius,
                        cogRadius: cogRadius
                    )
                    lowerReturnLength = tensionChainLength
                    
                    let topOutChainringPos = Point2D(x: geometry.chainringOffsetX, y: geometry.bbHeight + geometry.chainringOffsetY)
                    let topOutCogPos = Point2D(x: initialAxleX, y: rearWheelRadius)
                    topOutTensionLength = calculateChainLength(
                        from: topOutChainringPos,
                        to: topOutCogPos,
                        chainringRadius: chainringRadius,
                        cogRadius: cogRadius
                    )
                    topOutLowerReturnLength = topOutTensionLength
                }
            }
        }
        
        // Calculate chain growth for both tension path (for kickback) and total path (for derailleur capacity)
        let tensionChainGrowth = tensionChainLength - topOutTensionLength
        let chainringCircumference = 2.0 * .pi * chainringRadius
        let pedalKickback = (tensionChainGrowth / chainringCircumference) * 360.0
        
        let totalChainLength = tensionChainLength + lowerReturnLength
        let topOutTotalLength = topOutTensionLength + topOutLowerReturnLength
        let totalChainGrowth = totalChainLength - topOutTotalLength
        
        // We don't calculate AS/AR here - they're measured visually later
        let antiSquat = 0.0  // Placeholder - will be measured from visual geometry
        let antiRise = 0.0   // Placeholder - will be measured from visual geometry
        
        let wheelRate = geometry.shockSpringRate / (leverageRatio * leverageRatio)
        
        // Calculate mechanical trail: perpendicular distance from contact patch to head tube axis
        // This must be calculated in SCREEN SPACE (after pitch rotation) to match visual overlay
        
        // Apply pitch rotation to all points (rotate around rear axle)
        let pitchRad = pitchAngleDegrees * .pi / 180.0
        func applyPitchRotation(_ point: Point2D) -> Point2D {
            let dx = point.x - rearAxlePos.x
            let dy = point.y - rearAxlePos.y
            let cosP = cos(-pitchRad)
            let sinP = sin(-pitchRad)
            return Point2D(
                x: rearAxlePos.x + dx * cosP - dy * sinP,
                y: rearAxlePos.y + dx * sinP + dy * cosP
            )
        }
        
        // Contact patch at ground level (no pitch rotation needed as it's already at y=0)
        let contactPatch = Point2D(x: frontAxlePos.x, y: 0)
        
        // Head tube line after pitch rotation
        let htTopWorld = Point2D(x: bbPos.x + geometry.reach, y: bbPos.y + geometry.stack)
        let htBottomWorld = Point2D(
            x: htTopWorld.x + geometry.headTubeLength * cos(htaRad),
            y: htTopWorld.y - geometry.headTubeLength * sin(htaRad)
        )
        let htTop = applyPitchRotation(htTopWorld)
        let htBottom = applyPitchRotation(htBottomWorld)
        
        // Calculate perpendicular distance from contact patch to head tube line (in screen/pitch-rotated space)
        let lineVecX = htBottom.x - htTop.x
        let lineVecY = htBottom.y - htTop.y
        let numerator = abs(lineVecY * (contactPatch.x - htTop.x) - lineVecX * (contactPatch.y - htTop.y))
        let denominator = sqrt(lineVecX * lineVecX + lineVecY * lineVecY)
        let trail = numerator / denominator
        
        // Calculate crank angle from pedal kickback (negative because kickback rotates backwards)
        let crankAngle = -pedalKickback
        
        return KinematicState(
            travelMM: wheelTravel,
            rearAxlePosition: rearAxlePos,
            bbPosition: bbPos,
            pivotPosition: finalPivotPos,
            swingarmEyePosition: finalSwingarmEye,
            frontAxlePosition: frontAxlePos,
            shockLength: shockLength,
            leverageRatio: leverageRatio,
            antiSquat: antiSquat,
            antiRise: antiRise,
            pedalKickback: pedalKickback,
            chainGrowth: tensionChainGrowth,
            totalChainGrowth: totalChainGrowth,
            wheelRate: wheelRate,
            trail: trail,
            crankAngle: crankAngle,
            forkCompression: forkCompression,
            pitchAngleDegrees: pitchAngleDegrees
        )
    }
    
    // MARK: - Helper Functions
    
    
    // MARK: - Animation Control
    
    func startAnimation() {
        guard !analysisResults.states.isEmpty else { return }
        
        isAnimating = true
        animationTimer?.invalidate()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    func stopAnimation() {
        isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateAnimation() {
        let increment = 0.5 * animationSpeed
        currentTravelMM += increment
        
        // Advance fork proportionally
        let shockRatio = currentTravelMM / geometry.shockStroke
        currentForkStroke = shockRatio * geometry.forkTravel
        
        if currentTravelMM >= geometry.shockStroke {
            currentTravelMM = 0
            currentForkStroke = 0
        }
    }
    
    func setTravel(_ travel: Double) {
        currentTravelMM = min(max(travel, 0), geometry.shockStroke)
        if slidersLinked {
            let ratio = currentTravelMM / geometry.shockStroke
            currentForkStroke = ratio * geometry.forkTravel
        }
    }
    
    func setForkStroke(_ stroke: Double) {
        currentForkStroke = min(max(stroke, 0), geometry.forkTravel)
        if slidersLinked {
            let ratio = currentForkStroke / geometry.forkTravel
            currentTravelMM = ratio * geometry.shockStroke
        }
    }
    
    // MARK: - Current State
    
    func getCurrentState() -> KinematicState? {
        return getStateAt(shockStroke: currentTravelMM, forkStroke: currentForkStroke)
    }
    
    // Get state at any shock/fork combination (for both animation and graphs)
    func getStateAt(shockStroke: Double, forkStroke: Double) -> KinematicState? {
        // Calculate rigid triangle once
        let rigidTriangle = BikeViewModel.establishRigidTriangle(geometry: geometry)
        
        // Calculate state at specified shock stroke
        var state = BikeViewModel.calculateStateAtShockStroke(
            shockStroke: shockStroke,
            geometry: geometry,
            rigidTriangle: rigidTriangle
        )
        
        // Use specified fork stroke value
        state.forkCompression = forkStroke
        
        // Recalculate front axle and pitch with specified fork compression
        let htaRad = geometry.headAngle * .pi / 180.0
        let effectiveForkLength = geometry.forkLength - forkStroke
        
        var frontAxlePos = Point2D(
            x: state.bbPosition.x + geometry.reach + geometry.headTubeLength * cos(htaRad) + effectiveForkLength * cos(htaRad) + geometry.forkOffset * sin(htaRad),
            y: state.bbPosition.y + geometry.stack - geometry.headTubeLength * sin(htaRad) - effectiveForkLength * sin(htaRad) + geometry.forkOffset * cos(htaRad)
        )
        
        // Recalculate pitch with specified fork compression
        let rearCenter = state.rearAxlePosition
        let frontCenter = frontAxlePos
        
        let dx = frontCenter.x - rearCenter.x
        let dy = frontCenter.y - rearCenter.y
        let centerDist = sqrt(dx * dx + dy * dy)
        
        let centerAngle = atan2(dy, dx)
        let radiusDiff = geometry.frontWheelRadius - geometry.rearWheelRadius
        let angleOffset = asin(radiusDiff / centerDist)
        let tangentAngle = centerAngle - angleOffset
        let pitchAngle = tangentAngle
        
        state.pitchAngleDegrees = pitchAngle * 180.0 / .pi
        
        // Store front axle position (NOT rotated - drawing code will apply pitch)
        state.frontAxlePosition = frontAxlePos
        
        // MEASURE anti-squat and anti-rise from visual geometry (not calculate)
        state.antiSquat = calculateVisualAntiSquat(state: state, geometry: geometry)
        state.antiRise = calculateVisualAntiRise(state: state, geometry: geometry)
        
        // Recalculate trail dynamically based on current fork compression and pitch
        // This must be calculated in SCREEN SPACE (after pitch rotation) to match visual overlay
        let pitchRad = state.pitchAngleDegrees * .pi / 180.0
        func applyPitchRotation(_ point: Point2D) -> Point2D {
            let dx = point.x - state.rearAxlePosition.x
            let dy = point.y - state.rearAxlePosition.y
            let cosP = cos(-pitchRad)
            let sinP = sin(-pitchRad)
            return Point2D(
                x: state.rearAxlePosition.x + dx * cosP - dy * sinP,
                y: state.rearAxlePosition.y + dx * sinP + dy * cosP
            )
        }
        
        // Apply pitch rotation to front axle, then contact patch is at that X position, y=0
        let rotatedFrontAxle = applyPitchRotation(frontAxlePos)
        let contactPatch = Point2D(x: rotatedFrontAxle.x, y: 0)
        
        // Head tube line after pitch rotation
        let htTopWorld = Point2D(x: state.bbPosition.x + geometry.reach, y: state.bbPosition.y + geometry.stack)
        let htBottomWorld = Point2D(
            x: htTopWorld.x + geometry.headTubeLength * cos(htaRad),
            y: htTopWorld.y - geometry.headTubeLength * sin(htaRad)
        )
        let htTop = applyPitchRotation(htTopWorld)
        let htBottom = applyPitchRotation(htBottomWorld)
        
        // Calculate perpendicular distance from contact patch to head tube line
        let lineVecX = htBottom.x - htTop.x
        let lineVecY = htBottom.y - htTop.y
        let numerator = abs(lineVecY * (contactPatch.x - htTop.x) - lineVecX * (contactPatch.y - htTop.y))
        let denominator = sqrt(lineVecX * lineVecX + lineVecY * lineVecY)
        state.trail = numerator / denominator
        
        return state
    }
}
