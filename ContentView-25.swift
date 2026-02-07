//
//  contentview-25.swift
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

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: BikeViewModel
    
    var body: some View {
        NavigationSplitView {
            // Input panel (sidebar)
            InputPanel(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 400)
        } detail: {
            // Main content area;seeuarvaoiwvcaoeirjg
            VStack(spacing: 0) {
                // Animation window
                AnimationView(viewModel: viewModel)
                    .frame(maxHeight: .infinity)
                
                Divider()
                
                // Graph area
                GraphPanel(viewModel: viewModel)
                    .frame(height: 400)
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }
}

// MARK: - Input Panel

struct InputPanel: View {
    @ObservedObject var viewModel: BikeViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Bike Geometry")
                    .font(.title2)
                    .bold()
                
                // Frame section
                GroupBox("Frame") {
                    GeometryInputs(viewModel: viewModel)
                }
                
                // Suspension section
                GroupBox("Suspension") {
                    SuspensionInputs(viewModel: viewModel)
                }
                
                // Shock section
                GroupBox("Shock") {
                    ShockInputs(viewModel: viewModel)
                }
                
                // Drivetrain section
                GroupBox("Drivetrain") {
                    DrivetrainInputs(viewModel: viewModel)
                }
            }
            .padding()
        }
    }
}

// MARK: - Input Sections (Placeholders)

struct GeometryInputs: View {
    @ObservedObject var viewModel: BikeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NumberField("BB Height (mm)", value: $viewModel.geometry.bbHeight)
            NumberField("Stack (mm)", value: $viewModel.geometry.stack)
            NumberField("Reach (mm)", value: $viewModel.geometry.reach)
            NumberField("Head Angle (°)", value: $viewModel.geometry.headAngle)
            NumberField("Head Tube Length (mm)", value: $viewModel.geometry.headTubeLength)
            NumberField("Seat Tube Length (mm)", value: $viewModel.geometry.seatTubeLength)
            NumberField("Fork Length (mm)", value: $viewModel.geometry.forkLength)
            NumberField("Fork Offset (mm)", value: $viewModel.geometry.forkOffset)
            NumberField("Fork Travel (mm)", value: $viewModel.geometry.forkTravel)
            
            Divider().padding(.vertical, 4)
            
            Text("Wheel Diameters:")
                .font(.caption)
                .foregroundStyle(.secondary)
            NumberField("  Front (mm)", value: $viewModel.geometry.frontWheelDiameter)
            NumberField("  Rear (mm)", value: $viewModel.geometry.rearWheelDiameter)
        }
    }
}

struct SuspensionInputs: View {
    @ObservedObject var viewModel: BikeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display max wheel travel (computed from kinematics)
            HStack {
                Text("Travel (mm)")
                Spacer()
                Text(String(format: "%.1f", viewModel.analysisResults.states.last?.travelMM ?? 0))
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .trailing)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            NumberField("Swingarm Length (pivot to axle, mm)", value: $viewModel.geometry.swingarmLength)
            NumberField("Pivot X (mm)", value: $viewModel.geometry.bbToPivotX)
            NumberField("Pivot Y (mm)", value: $viewModel.geometry.bbToPivotY)
        }
    }
}

struct ShockInputs: View {
    @ObservedObject var viewModel: BikeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NumberField("Stroke (mm)", value: $viewModel.geometry.shockStroke)
            NumberField("Eye-to-Eye (mm)", value: $viewModel.geometry.shockETE)
            
            Text("Frame Mount (from BB):")
                .font(.caption)
                .foregroundStyle(.secondary)
            NumberField("  X (mm)", value: $viewModel.geometry.shockFrameMountX)
            NumberField("  Y (mm)", value: $viewModel.geometry.shockFrameMountY)
            
            Text("Swingarm Mount:")
                .font(.caption)
                .foregroundStyle(.secondary)
            NumberField("  Distance from pivot (mm)", value: $viewModel.geometry.shockSwingarmMountDistance)
            Text("  (positive = away from axle)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct DrivetrainInputs: View {
    @ObservedObject var viewModel: BikeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Chainring Teeth:")
                TextField("", value: $viewModel.geometry.chainringTeeth, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
            HStack {
                Text("Cog Teeth:")
                TextField("", value: $viewModel.geometry.cogTeeth, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
            
            Divider().padding(.vertical, 4)
            
            Text("Idler:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("Type", selection: $viewModel.geometry.idlerType) {
                ForEach(BikeGeometry.IdlerType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            if viewModel.geometry.idlerType != .none {
                Text("  (position at top-out)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                NumberField("  X (mm from BB)", value: $viewModel.geometry.idlerX)
                NumberField("  Y (mm from BB)", value: $viewModel.geometry.idlerY)
                HStack {
                    Text("  Teeth:")
                    TextField("", value: $viewModel.geometry.idlerTeeth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }
            
            Divider().padding(.vertical, 4)
            
            Text("Center of Mass (from BB):")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            NumberField("  X (mm)", value: $viewModel.geometry.comX)
            NumberField("  Y (mm)", value: $viewModel.geometry.comY)
        }
    }
}

// MARK: - Animation View

struct AnimationView: View {
    @ObservedObject var viewModel: BikeViewModel
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Canvas { context, size in
                    guard let state = viewModel.getCurrentState() else {
                        // No data yet
                        context.draw(
                            Text("Press Calculate to see bike animation")
                                .font(.title2),
                            at: CGPoint(x: size.width / 2, y: size.height / 2)
                        )
                        return
                    }
                    
                    // Pixels per mm (smaller divisor = larger bike)
                    let scale: CGFloat = min(size.width, size.height) / 1600.0
                    let offsetX = size.width / 2 - 400 * scale
                    let offsetY = size.height - 100  // Bottom margin
                    
                    // Pitch rotation helper
                    let pitchRad = state.pitchAngleDegrees * .pi / 180.0
                    let rearAxleWorld = state.rearAxlePosition
                    
                    func toScreen(_ point: Point2D) -> CGPoint {
                        let dx = point.x - rearAxleWorld.x
                        let dy = point.y - rearAxleWorld.y
                        let cosA = cos(-pitchRad)
                        let sinA = sin(-pitchRad)
                        let rx = rearAxleWorld.x + dx * cosA - dy * sinA
                        let ry = rearAxleWorld.y + dx * sinA + dy * cosA
                        return CGPoint(
                            x: offsetX + CGFloat(rx) * scale,
                            y: offsetY - CGFloat(ry) * scale
                        )
                    }
                    
                    let geo = viewModel.geometry
                    let bb = toScreen(state.bbPosition)
                    let pivot = toScreen(state.pivotPosition)
                    let rearAxle = toScreen(state.rearAxlePosition)
                    
                    // Calculate front end geometry with fork compression
                    let htaRad = geo.headAngle * .pi / 180.0
                    let htTopWorldX = state.bbPosition.x + geo.reach
                    let htTopWorldY = state.bbPosition.y + geo.stack
                    let cosHT = cos(htaRad)
                    let sinHT = sin(htaRad)
                    let htBottomWorldX = htTopWorldX + geo.headTubeLength * cosHT
                    let htBottomWorldY = htTopWorldY - geo.headTubeLength * sinHT
                    let htTop = toScreen(Point2D(x: htTopWorldX, y: htTopWorldY))
                    let htBottom = toScreen(Point2D(x: htBottomWorldX, y: htBottomWorldY))

                    // Fork length reduced by compression (toScreen will apply pitch rotation)
                    let effectiveForkLength = geo.forkLength - state.forkCompression
                    let frontAxleWorldX = htBottomWorldX + effectiveForkLength * cosHT + geo.forkOffset * sinHT
                    let frontAxleWorldY = htBottomWorldY - effectiveForkLength * sinHT + geo.forkOffset * cosHT
                    let frontAxle = toScreen(Point2D(x: frontAxleWorldX, y: frontAxleWorldY))
                    
                    // Ground line
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: offsetY))
                            path.addLine(to: CGPoint(x: size.width, y: offsetY))
                        },
                        with: .color(.gray),
                        lineWidth: 1.33
                    )
                    
                    // Wheels
                    let frontWheelRadius = geo.frontWheelRadius * scale
                    let rearWheelRadius = geo.rearWheelRadius * scale
                    
                    context.stroke(
                        Circle().path(in: CGRect(
                            x: frontAxle.x - frontWheelRadius,
                            y: frontAxle.y - frontWheelRadius,
                            width: frontWheelRadius * 2,
                            height: frontWheelRadius * 2
                        )),
                        with: .color(.white),
                        lineWidth: 1.33
                    )
                    
                    context.stroke(
                        Circle().path(in: CGRect(
                            x: rearAxle.x - rearWheelRadius,
                            y: rearAxle.y - rearWheelRadius,
                            width: rearWheelRadius * 2,
                            height: rearWheelRadius * 2
                        )),
                        with: .color(.white),
                        lineWidth: 1.33
                    )
                    
                    // Frame - Downtube (meets head tube 20mm above bottom)
                    let downtubeJunctionY = htBottom.y - 20 * scale  // 20mm above in screen coords (Y is inverted)
                    let downtubeJunctionRatio = (htTop.y - downtubeJunctionY) / (htTop.y - htBottom.y)
                    let downtubeJunction = CGPoint(
                        x: htBottom.x + (htTop.x - htBottom.x) * (1.0 - downtubeJunctionRatio),
                        y: downtubeJunctionY
                    )
                    context.stroke(
                        Path { path in
                            path.move(to: bb)
                            path.addLine(to: downtubeJunction)
                        },
                        with: .color(.blue),
                        lineWidth: 2.67
                    )
                    
                    // Head tube
                    context.stroke(
                        Path { path in
                            path.move(to: htBottom)
                            path.addLine(to: htTop)
                        },
                        with: .color(.blue),
                        lineWidth: 2.67
                    )
                    
                    // Seat tube (slopes backward) - uses seatTubeLength
                    let seatAngleRad = geo.seatAngle * .pi / 180.0
                    let seatTop = toScreen(Point2D(
                        x: state.bbPosition.x - geo.seatTubeLength * cos(seatAngleRad),
                        y: state.bbPosition.y + geo.seatTubeLength * sin(seatAngleRad)
                    ))
                    context.stroke(
                        Path { path in
                            path.move(to: bb)
                            path.addLine(to: seatTop)
                        },
                        with: .color(.blue),
                        lineWidth: 2.67
                    )
                    
                    // Top tube (approximate)
                    context.stroke(
                        Path { path in
                            path.move(to: htTop)
                            path.addLine(to: seatTop)
                        },
                        with: .color(.blue),
                        lineWidth: 1.33
                    )
                    
                    // Center of Mass indicator
                    let comScreen = toScreen(Point2D(
                        x: state.bbPosition.x + geo.comX,
                        y: state.bbPosition.y + geo.comY
                    ))
                    context.stroke(
                        Circle().path(in: CGRect(
                            x: comScreen.x - 15,
                            y: comScreen.y - 15,
                            width: 30,
                            height: 30
                        )),
                        with: .color(.white.opacity(0.6)),
                        lineWidth: 1.33
                    )
                    context.fill(
                        Circle().path(in: CGRect(
                            x: comScreen.x - 3,
                            y: comScreen.y - 3,
                            width: 6,
                            height: 6
                        )),
                        with: .color(.white.opacity(0.6))
                    )
                    
                    // Fork - follows steering axis then 90 degree corner to offset
                    // Point where fork bends (at end of fork length along steering axis)
                    let forkBendWorldX = htBottomWorldX + effectiveForkLength * cosHT
                    let forkBendWorldY = htBottomWorldY - effectiveForkLength * sinHT
                    let forkBendPoint = toScreen(Point2D(x: forkBendWorldX, y: forkBendWorldY))
                    
                    // Fork stanchions (along steering axis)
                    context.stroke(
                        Path { path in
                            path.move(to: htBottom)
                            path.addLine(to: forkBendPoint)
                        },
                        with: .color(.green),
                        lineWidth: 2.67
                    )
                    
                    // Fork lower legs (perpendicular to steering axis, toward front of bike)
                    context.stroke(
                        Path { path in
                            path.move(to: forkBendPoint)
                            path.addLine(to: frontAxle)
                        },
                        with: .color(.green),
                        lineWidth: 2.67
                    )
                    
                    // Shock - use stored eye position from state (already calculated as part of rigid triangle)
                    let frameMountWorld = Point2D(x: state.bbPosition.x + geo.shockFrameMountX, y: state.bbPosition.y + geo.shockFrameMountY)
                    let shockEyeWorld = state.swingarmEyePosition
                    
                    let shockFrame = toScreen(frameMountWorld)
                    let shockSwingarm = toScreen(shockEyeWorld)
                    
                    // Draw swingarm triangle (orange) - pivot, eye, axle form rigid structure
                    context.stroke(
                        Path { path in
                            path.move(to: pivot)
                            path.addLine(to: shockSwingarm)
                            path.addLine(to: rearAxle)
                            path.addLine(to: pivot)
                        },
                        with: .color(.orange),
                        lineWidth: 1.33
                    )
                    
                    context.stroke(
                        Path { path in
                            path.move(to: shockFrame)
                            path.addLine(to: shockSwingarm)
                        },
                        with: .color(.red),
                        lineWidth: 1.33
                    )
                    
                    // Shock mount points (eyes)
                    context.fill(
                        Circle().path(in: CGRect(x: shockFrame.x - 5, y: shockFrame.y - 5, width: 10, height: 10)),
                        with: .color(.red)
                    )
                    context.fill(
                        Circle().path(in: CGRect(x: shockSwingarm.x - 5, y: shockSwingarm.y - 5, width: 10, height: 10)),
                        with: .color(.red)
                    )
                    
                    // Pivot point (hollow)
                    context.stroke(
                        Circle().path(in: CGRect(x: pivot.x - 6, y: pivot.y - 6, width: 12, height: 12)),
                        with: .color(.yellow),
                        lineWidth: 1.33
                    )
                    
                    // BB point
                    context.fill(
                        Circle().path(in: CGRect(x: bb.x - 4, y: bb.y - 4, width: 8, height: 8)),
                        with: .color(.cyan)
                    )
                    
                    // Drivetrain - Chainring and Cog
                    let chainringPos = Point2D(x: state.bbPosition.x + geo.chainringOffsetX, y: state.bbPosition.y + geo.chainringOffsetY)
                    let cogPos = state.rearAxlePosition
                    let chainringRadius = sprocketRadius(teeth: geo.chainringTeeth)
                    let cogRadius = sprocketRadius(teeth: geo.cogTeeth)
                    
                    let chainringScreen = toScreen(chainringPos)
                    let cogScreen = toScreen(cogPos)
                    let chainringRadiusScreen = chainringRadius * scale
                    let cogRadiusScreen = cogRadius * scale
                    
                    // Draw chainring
                    context.stroke(
                        Circle().path(in: CGRect(
                            x: chainringScreen.x - chainringRadiusScreen,
                            y: chainringScreen.y - chainringRadiusScreen,
                            width: chainringRadiusScreen * 2,
                            height: chainringRadiusScreen * 2
                        )),
                        with: .color(.yellow),
                        lineWidth: 1.33
                    )
                    
                    // Draw crank for chain/pedal kickback overlays
                    if viewModel.selectedGraph == .pedalKickback || viewModel.selectedGraph == .chainGrowth {
                        let crankLength = 165.0 * scale  // 165mm standard crank
                        let crankAngleRad = state.crankAngle * .pi / 180.0
                        
                        // Drive side crank (starts at 3 o'clock = 0° at top-out)
                        let crankEnd = CGPoint(
                            x: chainringScreen.x + crankLength * cos(crankAngleRad),
                            y: chainringScreen.y - crankLength * -sin(crankAngleRad)
                        )
                        
                        // Draw crank arm
                        context.stroke(
                            Path { path in
                                path.move(to: chainringScreen)
                                path.addLine(to: crankEnd)
                            },
                            with: .color(.gray),
                            lineWidth: 2.67
                        )
                        
                        // Draw pedal
                        context.fill(
                            Circle().path(in: CGRect(x: crankEnd.x - 5, y: crankEnd.y - 5, width: 10, height: 10)),
                            with: .color(.white)
                        )
                    }
                    
                    // Draw cog
                    context.stroke(
                        Circle().path(in: CGRect(
                            x: cogScreen.x - cogRadiusScreen,
                            y: cogScreen.y - cogRadiusScreen,
                            width: cogRadiusScreen * 2,
                            height: cogRadiusScreen * 2
                        )),
                        with: .color(.yellow),
                        lineWidth: 1.33
                    )
                    
                    // Draw chain
                    if geo.idlerType == .none {
                        // Simple chain - direct connection with tangent lines
                        let dx = cogPos.x - chainringPos.x
                        let dy = cogPos.y - chainringPos.y
                        let dist = sqrt(dx * dx + dy * dy)
                        let angle = atan2(dy, dx)
                        
                        let radiusDiff = chainringRadius - cogRadius
                        let tangentAngle = asin(radiusDiff / dist)
                        
                        // Upper tangent
                        let upperAngle = angle + tangentAngle
                        let chainringUpper = Point2D(
                            x: chainringPos.x + chainringRadius * sin(upperAngle),
                            y: chainringPos.y - chainringRadius * cos(upperAngle)
                        )
                        let cogUpper = Point2D(
                            x: cogPos.x + cogRadius * sin(upperAngle),
                            y: cogPos.y - cogRadius * cos(upperAngle)
                        )
                        
                        // Lower tangent  
                        let lowerAngle = angle - tangentAngle + .pi
                        let chainringLower = Point2D(
                            x: chainringPos.x + chainringRadius * sin(lowerAngle),
                            y: chainringPos.y - chainringRadius * cos(lowerAngle)
                        )
                        let cogLower = Point2D(
                            x: cogPos.x + cogRadius * sin(lowerAngle),
                            y: cogPos.y - cogRadius * cos(lowerAngle)
                        )
                        
                        context.stroke(
                            Path { path in
                                path.move(to: toScreen(chainringUpper))
                                path.addLine(to: toScreen(cogUpper))
                            },
                            with: .color(.yellow.opacity(0.7)),
                            lineWidth: 1
                        )
                        
                        context.stroke(
                            Path { path in
                                path.move(to: toScreen(chainringLower))
                                path.addLine(to: toScreen(cogLower))
                            },
                            with: .color(.yellow.opacity(0.7)),
                            lineWidth: 1
                        )
                    } else {
                        // Chain with idler
                        let idlerPos: Point2D
                        if geo.idlerType == .frameMounted {
                            // Frame mounted - position relative to BB
                            idlerPos = Point2D(x: state.bbPosition.x + geo.idlerX, y: state.bbPosition.y + geo.idlerY)
                        } else { // swingarm mounted
                            // Swingarm mounted - idler rotates with swingarm
                            // Calculate offset from pivot at top-out
                            let topOutIdlerX = geo.idlerX - geo.bbToPivotX
                            let topOutIdlerY = (geo.bbHeight + geo.idlerY) - (geo.bbHeight + geo.bbToPivotY)
                            
                            // Calculate swingarm angle at top-out
                            let topOutPivot = Point2D(x: geo.bbToPivotX, y: geo.bbHeight + geo.bbToPivotY)
                            let topOutVertDist = geo.rearWheelRadius - topOutPivot.y
                            let topOutHorizDist = sqrt(geo.swingarmLength * geo.swingarmLength - topOutVertDist * topOutVertDist)
                            let topOutAxle = Point2D(x: topOutPivot.x - topOutHorizDist, y: geo.rearWheelRadius)
                            let topOutSwingarmAngle = atan2(topOutAxle.y - topOutPivot.y, topOutAxle.x - topOutPivot.x)
                            
                            // Calculate current swingarm angle
                            let currentSwingarmAngle = atan2(state.rearAxlePosition.y - state.pivotPosition.y, 
                                                            state.rearAxlePosition.x - state.pivotPosition.x)
                            
                            // Rotation angle
                            let rotationAngle = currentSwingarmAngle - topOutSwingarmAngle
                            
                            // Rotate idler offset
                            let rotatedOffsetX = topOutIdlerX * cos(rotationAngle) - topOutIdlerY * sin(rotationAngle)
                            let rotatedOffsetY = topOutIdlerX * sin(rotationAngle) + topOutIdlerY * cos(rotationAngle)
                            
                            // Apply to current pivot position
                            idlerPos = Point2D(
                                x: state.pivotPosition.x + rotatedOffsetX,
                                y: state.pivotPosition.y + rotatedOffsetY
                            )
                        }
                        
                        let idlerRadius = sprocketRadius(teeth: geo.idlerTeeth)
                        let idlerScreen = toScreen(idlerPos)
                        let idlerRadiusScreen = idlerRadius * scale
                        
                        // Draw idler
                        context.stroke(
                            Circle().path(in: CGRect(
                                x: idlerScreen.x - idlerRadiusScreen,
                                y: idlerScreen.y - idlerRadiusScreen,
                                width: idlerRadiusScreen * 2,
                                height: idlerRadiusScreen * 2
                            )),
                            with: .color(.orange),
                            lineWidth: 1.33
                        )
                        
                        // Calculate chain routing with proper tangents
                        // Segment 1: Chainring to Idler
                        let dx1 = idlerPos.x - chainringPos.x
                        let dy1 = idlerPos.y - chainringPos.y
                        let dist1 = sqrt(dx1 * dx1 + dy1 * dy1)
                        let angle1 = atan2(dy1, dx1)
                        
                        let radiusDiff1 = chainringRadius - idlerRadius
                        let tangentAngle1 = asin(radiusDiff1 / dist1)
                        
                        // Use upper tangent (tight side of chain)
                        let upperAngle1 = angle1 + tangentAngle1
                        let chainringToIdler1 = Point2D(
                            x: chainringPos.x + chainringRadius * sin(upperAngle1),
                            y: chainringPos.y - chainringRadius * cos(upperAngle1)
                        )
                        let idlerFromChainring1 = Point2D(
                            x: idlerPos.x + idlerRadius * sin(upperAngle1),
                            y: idlerPos.y - idlerRadius * cos(upperAngle1)
                        )
                        
                        // Segment 2: Idler to Cog
                        let dx2 = cogPos.x - idlerPos.x
                        let dy2 = cogPos.y - idlerPos.y
                        let dist2 = sqrt(dx2 * dx2 + dy2 * dy2)
                        let angle2 = atan2(dy2, dx2)
                        
                        let radiusDiff2 = idlerRadius - cogRadius
                        let tangentAngle2 = asin(radiusDiff2 / dist2)
                        
                        // Use upper tangent
                        let upperAngle2 = angle2 + tangentAngle2
                        let idlerToCog2 = Point2D(
                            x: idlerPos.x + idlerRadius * sin(upperAngle2),
                            y: idlerPos.y - idlerRadius * cos(upperAngle2)
                        )
                        let cogFromIdler2 = Point2D(
                            x: cogPos.x + cogRadius * sin(upperAngle2),
                            y: cogPos.y - cogRadius * cos(upperAngle2)
                        )
                        
                        // Draw chain segments
                        context.stroke(
                            Path { path in
                                path.move(to: toScreen(chainringToIdler1))
                                path.addLine(to: toScreen(idlerFromChainring1))
                            },
                            with: .color(.yellow.opacity(0.7)),
                            lineWidth: 1
                        )
                        
                        context.stroke(
                            Path { path in
                                path.move(to: toScreen(idlerToCog2))
                                path.addLine(to: toScreen(cogFromIdler2))
                            },
                            with: .color(.yellow.opacity(0.7)),
                            lineWidth: 1
                        )
                        
                        // Return segment: Cog to Chainring (lower)
                        let dx3 = chainringPos.x - cogPos.x
                        let dy3 = chainringPos.y - cogPos.y
                        let dist3 = sqrt(dx3 * dx3 + dy3 * dy3)
                        let angle3 = atan2(dy3, dx3)
                        
                        let radiusDiff3 = cogRadius - chainringRadius
                        let tangentAngle3 = asin(radiusDiff3 / dist3)
                        
                        let lowerAngle3 = angle3 - tangentAngle3
                        let cogToChainring = Point2D(
                            x: cogPos.x + cogRadius * sin(lowerAngle3),
                            y: cogPos.y - cogRadius * cos(lowerAngle3)
                        )
                        let chainringFromCog = Point2D(
                            x: chainringPos.x + chainringRadius * sin(lowerAngle3),
                            y: chainringPos.y - chainringRadius * cos(lowerAngle3)
                        )
                        
                        context.stroke(
                            Path { path in
                                path.move(to: toScreen(cogToChainring))
                                path.addLine(to: toScreen(chainringFromCog))
                            },
                            with: .color(.yellow.opacity(0.7)),
                            lineWidth: 1
                        )
                    }
                    
                    // Technical drawing measurements (grey overlay)
                    let bbScreen = toScreen(state.bbPosition)
                    let rearAxleScreen = toScreen(state.rearAxlePosition)
                    let frontAxleComp = state.forkCompression
                    let htaRadMeasure = geo.headAngle * .pi / 180.0
                    
                    // Use stored front axle position (already calculated in getCurrentState with correct fork compression)
                    let frontAxleScreen = toScreen(state.frontAxlePosition)
                    let groundY = offsetY
                    let rearCenter = abs(state.rearAxlePosition.x - state.bbPosition.x)
                    
                    // Mechanical trail: horizontal distance from steering axis ground intersection to wheel contact
                    // Trail = (wheel radius + fork length) / tan(head angle) - fork offset
                    let trailDistance = (geo.frontWheelRadius + (geo.forkLength - state.forkCompression)) / tan(htaRadMeasure) - geo.forkOffset
                    
                    let measurementColor = Color.gray.opacity(0.5)
                    let measurementLineWidth: CGFloat = 0.67
                    
                    // BB Height (vertical line from BB to ground)
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: bbScreen.x, y: bbScreen.y))
                            path.addLine(to: CGPoint(x: bbScreen.x, y: groundY))
                        },
                        with: .color(measurementColor),
                        style: StrokeStyle(lineWidth: measurementLineWidth, dash: [3, 3])
                    )
                    
                    let bbHeightText = Text("BB: \(Int(state.bbPosition.y))mm")
                        .font(.caption2)
                        .foregroundColor(measurementColor)
                    context.draw(
                        bbHeightText,
                        at: CGPoint(x: bbScreen.x + 15, y: (bbScreen.y + groundY) / 2)
                    )
                    
                    // Rear Center (horizontal from BB to rear axle) - below ground
                    // Vertical lines from BB and rear axle to measurement line
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: bbScreen.x, y: groundY))
                            path.addLine(to: CGPoint(x: bbScreen.x, y: groundY + 30))
                        },
                        with: .color(measurementColor),
                        style: StrokeStyle(lineWidth: measurementLineWidth, dash: [3, 3])
                    )
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: rearAxleScreen.x, y: groundY))
                            path.addLine(to: CGPoint(x: rearAxleScreen.x, y: groundY + 30))
                        },
                        with: .color(measurementColor),
                        style: StrokeStyle(lineWidth: measurementLineWidth, dash: [3, 3])
                    )
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: bbScreen.x, y: groundY + 30))
                            path.addLine(to: CGPoint(x: rearAxleScreen.x, y: groundY + 30))
                        },
                        with: .color(measurementColor),
                        style: StrokeStyle(lineWidth: measurementLineWidth, dash: [3, 3])
                    )
                    
                    let rearCenterText = Text("RC: \(Int(rearCenter))mm")
                        .font(.caption2)
                        .foregroundColor(measurementColor)
                    context.draw(
                        rearCenterText,
                        at: CGPoint(x: (bbScreen.x + rearAxleScreen.x) / 2, y: groundY + 40)
                    )
                    
                    // Front Center (horizontal from BB to front axle) - below ground
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: bbScreen.x, y: groundY + 30))
                            path.addLine(to: CGPoint(x: bbScreen.x, y: groundY + 50))
                        },
                        with: .color(measurementColor),
                        style: StrokeStyle(lineWidth: measurementLineWidth, dash: [3, 3])
                    )
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: frontAxleScreen.x, y: groundY))
                            path.addLine(to: CGPoint(x: frontAxleScreen.x, y: groundY + 50))
                        },
                        with: .color(measurementColor),
                        style: StrokeStyle(lineWidth: measurementLineWidth, dash: [3, 3])
                    )
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: bbScreen.x, y: groundY + 50))
                            path.addLine(to: CGPoint(x: frontAxleScreen.x, y: groundY + 50))
                        },
                        with: .color(measurementColor),
                        style: StrokeStyle(lineWidth: measurementLineWidth, dash: [3, 3])
                    )
                    let frontCenter = abs(frontAxleScreen.x - bbScreen.x) / scale  // Convert back to mm
                    let frontCenterText = Text("FC: \(Int(frontCenter))mm")
                        .font(.caption2)
                        .foregroundColor(measurementColor)
                    context.draw(
                        frontCenterText,
                        at: CGPoint(x: (bbScreen.x + frontAxleScreen.x) / 2, y: groundY + 60)
                    )
                    
                    // Mechanical Trail - below ground
                    let trailText = Text("Trail: \(String(format: "%.1f", state.trail))mm")
                        .font(.caption2)
                        .foregroundColor(measurementColor)
                    context.draw(
                        trailText,
                        at: CGPoint(x: frontAxleScreen.x + 40, y: groundY + 20)
                    )
                    
                    // F/R Balance - below ground
                    let wheelbase = state.frontAxlePosition.x - state.rearAxlePosition.x
                    let comX = state.bbPosition.x + geo.comX
                    let distanceFromRear = comX - state.rearAxlePosition.x
                    let frontPercentage = (distanceFromRear / wheelbase) * 100
                    let rearPercentage = 100 - frontPercentage
                    
                    let balanceText = Text("F/R Balance: \(Int(frontPercentage))/\(Int(rearPercentage))")
                        .font(.caption2)
                        .foregroundColor(measurementColor)
                    context.draw(
                        balanceText,
                        at: CGPoint(x: (rearAxleScreen.x + frontAxleScreen.x) / 2, y: groundY + 70)
                    )
                    
                    // Display current metrics (moved to visible area)
                    let shockStroke = geo.shockETE - state.shockLength
                    let pitchDirection = state.pitchAngleDegrees > 0 ? "↓" : (state.pitchAngleDegrees < 0 ? "↑" : "—")
                    let metrics = """
                    Shock: \(String(format: "%.1f", shockStroke))mm (\(String(format: "%.1f", state.shockLength))mm)
                    Wheel Travel: \(String(format: "%.1f", state.travelMM))mm
                    LR: \(String(format: "%.2f", state.leverageRatio))
                    AS: \(String(format: "%.0f", state.antiSquat))%
                    Fork: \(String(format: "%.1f", state.forkCompression))mm
                    Pitch: \(String(format: "%.2f", abs(state.pitchAngleDegrees)))° \(pitchDirection)
                    """
                    
                    context.draw(
                        Text(metrics)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white),
                        at: CGPoint(x: size.width - 180, y: 40)
                    )
                    
                    // Pitch angle visualization
                    let pitchVisualizationX = size.width - 100
                    let pitchVisualizationY = size.height - 100
                    let pitchRadius: CGFloat = 40
                    
                    // Draw horizontal reference line
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: pitchVisualizationX - pitchRadius, y: pitchVisualizationY))
                            path.addLine(to: CGPoint(x: pitchVisualizationX + pitchRadius, y: pitchVisualizationY))
                        },
                        with: .color(.gray),
                        lineWidth: 1
                    )
                    
                    // Draw pitch angle arc (pitchRad already defined above)
                    context.stroke(
                        Path { path in
                            path.addArc(
                                center: CGPoint(x: pitchVisualizationX, y: pitchVisualizationY),
                                radius: pitchRadius * 0.6,
                                startAngle: .degrees(0),
                                endAngle: .degrees(state.pitchAngleDegrees),
                                clockwise: state.pitchAngleDegrees < 0
                            )
                        },
                        with: .color(.red),
                        lineWidth: 1.33
                    )
                    
                    // Draw angled line showing pitch
                    let pitchLineEndX = pitchVisualizationX + pitchRadius * cos(pitchRad)
                    let pitchLineEndY = pitchVisualizationY + pitchRadius * sin(pitchRad)
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: pitchVisualizationX, y: pitchVisualizationY))
                            path.addLine(to: CGPoint(x: pitchLineEndX, y: pitchLineEndY))
                        },
                        with: .color(.red),
                        lineWidth: 1.33
                    )
                    
                    // Draw pitch angle text
                    let pitchText = Text("\(String(format: "%.1f", abs(state.pitchAngleDegrees)))°")
                        .font(.caption)
                        .foregroundColor(.red)
                    context.draw(
                        pitchText,
                        at: CGPoint(x: pitchVisualizationX, y: pitchVisualizationY - pitchRadius - 15)
                    )
                    
                    // GEOMETRY OVERLAYS
                    drawGeometryOverlay(
                        context: context,
                        state: state,
                        geo: geo,
                        toScreen: toScreen,
                        size: size,
                        viewModel: viewModel
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            
            // Animation controls
            VStack(spacing: 8) {
                HStack {
                    Text("Shock Stroke:")
                        .frame(width: 100, alignment: .leading)
                    Slider(
                        value: Binding(
                            get: { viewModel.currentTravelMM },
                            set: { viewModel.setTravel($0) }
                        ),
                        in: 0...viewModel.geometry.shockStroke
                    )
                    Text("\(Int(viewModel.currentTravelMM))mm")
                        .frame(width: 60)
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.slidersLinked.toggle()
                    }) {
                        Image(systemName: viewModel.slidersLinked ? "link" : "link.badge.plus")
                            .font(.title3)
                            .foregroundColor(viewModel.slidersLinked ? .blue : .gray)
                    }
                    .buttonStyle(.plain)
                    .help(viewModel.slidersLinked ? "Linked - move together" : "Unlinked - move independently")
                    Spacer()
                }
                .frame(height: 20)
                
                HStack {
                    Text("Fork Stroke:")
                        .frame(width: 100, alignment: .leading)
                    Slider(
                        value: Binding(
                            get: { viewModel.currentForkStroke },
                            set: { viewModel.setForkStroke($0) }
                        ),
                        in: 0...viewModel.geometry.forkTravel
                    )
                    Text("\(Int(viewModel.currentForkStroke))mm")
                        .frame(width: 60)
                }
                
                Button(viewModel.isAnimating ? "Pause" : "Play") {
                    if viewModel.isAnimating {
                        viewModel.stopAnimation()
                    } else {
                        viewModel.startAnimation()
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Overlay Drawing Helper

func drawGeometryOverlay(
    context: GraphicsContext,
    state: KinematicState,
    geo: BikeGeometry,
    toScreen: (Point2D) -> CGPoint,
    size: CGSize,
    viewModel: BikeViewModel
) {
    let overlayColor = Color.cyan.opacity(0.8)
    let overlayLineWidth: CGFloat = 1.33
    
    switch viewModel.selectedGraph {
    case .antiSquat:
        // Anti-Squat construction geometry with proper IFC method
        let ic = toScreen(state.pivotPosition)
        let rearContact = toScreen(Point2D(x: state.rearAxlePosition.x, y: 0))
        let rearAxle = toScreen(state.rearAxlePosition)
        let frontContact = toScreen(Point2D(x: state.frontAxlePosition.x, y: 0))
        let com = toScreen(Point2D(x: state.bbPosition.x + geo.comX, y: state.bbPosition.y + geo.comY))
        
        // Calculate sprocket radii
        let chainringRadius = sprocketRadius(teeth: geo.chainringTeeth)
        let cogRadius = sprocketRadius(teeth: geo.cogTeeth)
        
        // Determine relevant chain line based on idler type (using tangent points)
        let chainLineStartWorld: Point2D
        let chainLineEndWorld: Point2D
        let chainLineLabel: String
        
        if geo.idlerType == .none {
            // No idler: chainring to cog, using upper tangent
            let chainringCenter = Point2D(x: state.bbPosition.x + geo.chainringOffsetX, y: state.bbPosition.y + geo.chainringOffsetY)
            let cogCenter = state.rearAxlePosition
            
            let dx = cogCenter.x - chainringCenter.x
            let dy = cogCenter.y - chainringCenter.y
            let dist = sqrt(dx * dx + dy * dy)
            let angle = atan2(dy, dx)
            let radiusDiff = chainringRadius - cogRadius
            let tangentAngle = asin(radiusDiff / dist)
            
            let upperAngle = angle + tangentAngle
            chainLineStartWorld = Point2D(
                x: chainringCenter.x + chainringRadius * sin(upperAngle),
                y: chainringCenter.y - chainringRadius * cos(upperAngle)
            )
            chainLineEndWorld = Point2D(
                x: cogCenter.x + cogRadius * sin(upperAngle),
                y: cogCenter.y - cogRadius * cos(upperAngle)
            )
            chainLineLabel = "Chain: Chainring→Cog"
        } else if geo.idlerType == .frameMounted {
            // Frame-mounted: idler to cog
            let idlerCenter = Point2D(x: state.bbPosition.x + geo.idlerX, y: state.bbPosition.y + geo.idlerY)
            let cogCenter = state.rearAxlePosition
            let idlerRadius = sprocketRadius(teeth: geo.idlerTeeth)
            
            let dx = cogCenter.x - idlerCenter.x
            let dy = cogCenter.y - idlerCenter.y
            let dist = sqrt(dx * dx + dy * dy)
            let angle = atan2(dy, dx)
            let radiusDiff = idlerRadius - cogRadius
            let tangentAngle = asin(radiusDiff / dist)
            
            let upperAngle = angle + tangentAngle
            chainLineStartWorld = Point2D(
                x: idlerCenter.x + idlerRadius * sin(upperAngle),
                y: idlerCenter.y - idlerRadius * cos(upperAngle)
            )
            chainLineEndWorld = Point2D(
                x: cogCenter.x + cogRadius * sin(upperAngle),
                y: cogCenter.y - cogRadius * cos(upperAngle)
            )
            chainLineLabel = "Chain: Idler→Cog"
        } else {
            // Swingarm-mounted: chainring to idler
            let topOutIdlerX = geo.idlerX - geo.bbToPivotX
            let topOutIdlerY = (geo.bbHeight + geo.idlerY) - (geo.bbHeight + geo.bbToPivotY)
            
            let topOutPivot = Point2D(x: geo.bbToPivotX, y: geo.bbHeight + geo.bbToPivotY)
            let topOutVertDist = geo.rearWheelRadius - topOutPivot.y
            let topOutHorizDist = sqrt(geo.swingarmLength * geo.swingarmLength - topOutVertDist * topOutVertDist)
            let topOutAxle = Point2D(x: topOutPivot.x - topOutHorizDist, y: geo.rearWheelRadius)
            let topOutSwingarmAngle = atan2(topOutAxle.y - topOutPivot.y, topOutAxle.x - topOutPivot.x)
            
            let currentSwingarmAngle = atan2(state.rearAxlePosition.y - state.pivotPosition.y,
                                            state.rearAxlePosition.x - state.pivotPosition.x)
            let rotationAngle = currentSwingarmAngle - topOutSwingarmAngle
            
            let rotatedOffsetX = topOutIdlerX * cos(rotationAngle) - topOutIdlerY * sin(rotationAngle)
            let rotatedOffsetY = topOutIdlerX * sin(rotationAngle) + topOutIdlerY * cos(rotationAngle)
            
            let idlerCenter = Point2D(
                x: state.pivotPosition.x + rotatedOffsetX,
                y: state.pivotPosition.y + rotatedOffsetY
            )
            
            let chainringCenter = Point2D(x: state.bbPosition.x + geo.chainringOffsetX, y: state.bbPosition.y + geo.chainringOffsetY)
            let idlerRadius = sprocketRadius(teeth: geo.idlerTeeth)
            
            let dx = idlerCenter.x - chainringCenter.x
            let dy = idlerCenter.y - chainringCenter.y
            let dist = sqrt(dx * dx + dy * dy)
            let angle = atan2(dy, dx)
            let radiusDiff = chainringRadius - idlerRadius
            let tangentAngle = asin(radiusDiff / dist)
            
            let upperAngle = angle + tangentAngle
            chainLineStartWorld = Point2D(
                x: chainringCenter.x + chainringRadius * sin(upperAngle),
                y: chainringCenter.y - chainringRadius * cos(upperAngle)
            )
            chainLineEndWorld = Point2D(
                x: idlerCenter.x + idlerRadius * sin(upperAngle),
                y: idlerCenter.y - idlerRadius * cos(upperAngle)
            )
            chainLineLabel = "Chain: Chainring→Idler"
        }
        
        let chainLineStart = toScreen(chainLineStartWorld)
        let chainLineEnd = toScreen(chainLineEndWorld)
        
        // Draw relevant chain line
        context.stroke(
            Path { path in
                path.move(to: chainLineStart)
                path.addLine(to: chainLineEnd)
            },
            with: .color(.white.opacity(0.8)),
            lineWidth: 1.33
        )
        
        // Draw IC to rear axle line
        context.stroke(
            Path { path in
                path.move(to: ic)
                path.addLine(to: rearAxle)
            },
            with: .color(overlayColor.opacity(0.5)),
            style: StrokeStyle(lineWidth: 1.33, dash: [3, 3])
        )
        
        // Calculate IFC (intersection of IC-rear-axle line with chain line)
        let ifc = lineIntersection(
            line1Point1: state.pivotPosition,
            line1Point2: state.rearAxlePosition,
            line2Point1: chainLineStartWorld,
            line2Point2: chainLineEndWorld
        )
        
        if let ifcWorld = ifc {
            let ifcScreen = toScreen(ifcWorld)
            
            // Highlight IFC point
            context.fill(
                Circle().path(in: CGRect(x: ifcScreen.x - 5, y: ifcScreen.y - 5, width: 10, height: 10)),
                with: .color(.orange)
            )
            
            // Draw line from rear contact through IFC
            let rearContactWorld = Point2D(x: state.rearAxlePosition.x, y: 0)
            let frontContactWorld = Point2D(x: state.frontAxlePosition.x, y: 0)
            let frontContactTop = Point2D(x: state.frontAxlePosition.x, y: 10000)
            
            let asIntersection = lineIntersection(
                line1Point1: rearContactWorld,
                line1Point2: ifcWorld,
                line2Point1: frontContactWorld,
                line2Point2: frontContactTop
            )
            
            if let asInt = asIntersection {
                let asIntScreen = toScreen(asInt)
                
                // Draw anti-squat line
                context.stroke(
                    Path { path in
                        path.move(to: rearContact)
                        path.addLine(to: asIntScreen)
                    },
                    with: .color(overlayColor),
                    style: StrokeStyle(lineWidth: overlayLineWidth, dash: [5, 5])
                )
                
                // Highlight AS intersection point
                context.fill(
                    Circle().path(in: CGRect(x: asIntScreen.x - 4, y: asIntScreen.y - 4, width: 8, height: 8)),
                    with: .color(.green.opacity(0.9))
                )
            }
            
            // Label IFC
            context.draw(
                Text("IFC").font(.caption).foregroundColor(.orange),
                at: CGPoint(x: ifcScreen.x + 15, y: ifcScreen.y)
            )
        }
        
        // Vertical line at front axle (in screen space)
        let frontAxleScreen = toScreen(state.frontAxlePosition)
        context.stroke(
            Path { path in
                path.move(to: CGPoint(x: frontAxleScreen.x, y: 0))
                path.addLine(to: CGPoint(x: frontAxleScreen.x, y: size.height))
            },
            with: .color(overlayColor),
            style: StrokeStyle(lineWidth: overlayLineWidth, dash: [5, 5])
        )
        
        // Horizontal line through COM
        context.stroke(
            Path { path in
                path.move(to: CGPoint(x: 0, y: com.y))
                path.addLine(to: CGPoint(x: size.width, y: com.y))
            },
            with: .color(overlayColor),
            style: StrokeStyle(lineWidth: overlayLineWidth, dash: [5, 5])
        )
        
        // Labels
        context.draw(
            Text("COM").font(.caption).foregroundColor(overlayColor),
            at: CGPoint(x: com.x + 15, y: com.y)
        )
        
    case .antiRise:
        // Anti-Rise construction geometry
        let ic = toScreen(state.pivotPosition)
        let frontContact = toScreen(Point2D(x: state.frontAxlePosition.x, y: 0))
        let rearContact = toScreen(Point2D(x: state.rearAxlePosition.x, y: 0))
        
        // Vertical line at front axle
        let frontAxleScreen = toScreen(state.frontAxlePosition)
        context.stroke(
            Path { path in
                path.move(to: CGPoint(x: frontAxleScreen.x, y: 0))
                path.addLine(to: CGPoint(x: frontAxleScreen.x, y: size.height))
            },
            with: .color(overlayColor),
            style: StrokeStyle(lineWidth: overlayLineWidth, dash: [5, 5])
        )
        
        // Calculate intersection of rear-IC line with front vertical
        let frontContactWorld = Point2D(x: state.frontAxlePosition.x, y: 0)
        let icWorld = state.pivotPosition
        let rearContactWorld = Point2D(x: state.rearAxlePosition.x, y: 0)
        let frontContactTop = Point2D(x: state.frontAxlePosition.x, y: 10000)
        
        let arIntersection = lineIntersection(
            line1Point1: rearContactWorld,
            line1Point2: icWorld,
            line2Point1: frontContactWorld,
            line2Point2: frontContactTop
        )
        
        // Line from rear contact through IC to vertical at front
        if let intersection = arIntersection {
            let intersectionScreen = toScreen(intersection)
            
            // Draw line from rear contact through IC to intersection
            context.stroke(
                Path { path in
                    path.move(to: rearContact)
                    path.addLine(to: intersectionScreen)
                },
                with: .color(overlayColor),
                style: StrokeStyle(lineWidth: overlayLineWidth, dash: [5, 5])
            )
            
            // Highlight intersection point
            context.fill(
                Circle().path(in: CGRect(x: intersectionScreen.x - 4, y: intersectionScreen.y - 4, width: 8, height: 8)),
                with: .color(.yellow)
            )
        } else {
            // Fallback: draw extended line from rear through IC
            let icAngle = atan2(ic.y - rearContact.y, ic.x - rearContact.x)
            let extensionLength: CGFloat = 2000
            let icLineEnd = CGPoint(
                x: rearContact.x + extensionLength * cos(icAngle),
                y: rearContact.y + extensionLength * sin(icAngle)
            )
            context.stroke(
                Path { path in
                    path.move(to: rearContact)
                    path.addLine(to: icLineEnd)
                },
                with: .color(overlayColor),
                style: StrokeStyle(lineWidth: overlayLineWidth, dash: [5, 5])
            )
        }
        
        // Draw COM horizontal line
        let comWorld = Point2D(x: state.bbPosition.x + geo.comX, y: state.bbPosition.y + geo.comY)
        let com = toScreen(comWorld)
        context.stroke(
            Path { path in
                path.move(to: CGPoint(x: 0, y: com.y))
                path.addLine(to: CGPoint(x: size.width, y: com.y))
            },
            with: .color(.cyan.opacity(0.5)),
            style: StrokeStyle(lineWidth: overlayLineWidth, dash: [5, 5])
        )
        
        context.draw(
            Text("COM").font(.caption).foregroundColor(.cyan),
            at: CGPoint(x: com.x + 15, y: com.y)
        )
        
    case .axlePath:
        // Show wheel paths - position them so current point touches current axle
        if !viewModel.analysisResults.axlePath.isEmpty && !viewModel.analysisResults.states.isEmpty {
            // Find current state index
            let currentIndex = min(Int(viewModel.currentTravelMM / 0.5), viewModel.analysisResults.states.count - 1)
            
            // Rear wheel path - offset so current point touches current rear axle
            let currentRearPathPoint = viewModel.analysisResults.axlePath[currentIndex]
            let pathOffsetRearX = state.rearAxlePosition.x - currentRearPathPoint.x - state.bbPosition.x
            let pathOffsetRearY = state.rearAxlePosition.y - currentRearPathPoint.y - state.bbPosition.y
            
            context.stroke(
                Path { path in
                    for (index, point) in viewModel.analysisResults.axlePath.enumerated() {
                        let worldPos = Point2D(
                            x: state.bbPosition.x + point.x + pathOffsetRearX,
                            y: state.bbPosition.y + point.y + pathOffsetRearY
                        )
                        let screenPos = toScreen(worldPos)
                        if index == 0 {
                            path.move(to: screenPos)
                        } else {
                            path.addLine(to: screenPos)
                        }
                    }
                },
                with: .color(.blue),
                lineWidth: 1.33
            )
            
            // Front wheel path - offset so current point touches current front axle
            if !viewModel.analysisResults.frontAxlePath.isEmpty {
                let currentFrontPathPoint = viewModel.analysisResults.frontAxlePath[currentIndex]
                let pathOffsetFrontX = state.frontAxlePosition.x - currentFrontPathPoint.x - state.bbPosition.x
                let pathOffsetFrontY = state.frontAxlePosition.y - currentFrontPathPoint.y - state.bbPosition.y
                
                context.stroke(
                    Path { path in
                        for (index, point) in viewModel.analysisResults.frontAxlePath.enumerated() {
                            let worldPos = Point2D(
                                x: state.bbPosition.x + point.x + pathOffsetFrontX,
                                y: state.bbPosition.y + point.y + pathOffsetFrontY
                            )
                            let screenPos = toScreen(worldPos)
                            if index == 0 {
                                path.move(to: screenPos)
                            } else {
                                path.addLine(to: screenPos)
                            }
                        }
                    },
                    with: .color(.red),
                    lineWidth: 1.33
                )
            }
        }
        
    case .trail:
        // Get the actual screen ground Y coordinate (same calculation as main render)
        let groundY = size.height - 100
        
        // Draw steering axis (head tube line extended)
        let htTop = toScreen(Point2D(x: state.bbPosition.x + geo.reach, y: state.bbPosition.y + geo.stack))
        let htaRad = geo.headAngle * .pi / 180.0
        let htBottom = toScreen(Point2D(
            x: state.bbPosition.x + geo.reach + geo.headTubeLength * cos(htaRad),
            y: state.bbPosition.y + geo.stack - geo.headTubeLength * sin(htaRad)
        ))
        
        // Extend steering axis line down to ground
        let lineVecX = htBottom.x - htTop.x
        let lineVecY = htBottom.y - htTop.y
        let lineLength: CGFloat = 1000
        let htExtended = CGPoint(x: htBottom.x + lineVecX * 2, y: htBottom.y + lineVecY * 2)
        
        context.stroke(
            Path { path in
                path.move(to: htTop)
                path.addLine(to: htExtended)
            },
            with: .color(.purple.opacity(0.6)),
            style: StrokeStyle(lineWidth: overlayLineWidth, dash: [5, 5])
        )
        
        // Draw perpendicular from front contact patch to steering axis
        // Use front axle screen X but actual ground Y to avoid pitch rotation issues
        let contactPatch = CGPoint(x: toScreen(state.frontAxlePosition).x, y: groundY)
        
        // Calculate closest point on steering axis line to contact patch IN SCREEN SPACE
        // This ensures the perpendicular stays perpendicular even with pitch rotation
        let lineVecScreenX = htBottom.x - htTop.x
        let lineVecScreenY = htBottom.y - htTop.y
        
        // Project contact patch onto steering axis (in screen coordinates)
        let dotProduct = (contactPatch.x - htTop.x) * lineVecScreenX + (contactPatch.y - htTop.y) * lineVecScreenY
        let lineLengthSquared = lineVecScreenX * lineVecScreenX + lineVecScreenY * lineVecScreenY
        let t = dotProduct / lineLengthSquared
        
        let closestPointScreen = CGPoint(
            x: htTop.x + t * lineVecScreenX,
            y: htTop.y + t * lineVecScreenY
        )
        
        // Draw perpendicular line
        context.stroke(
            Path { path in
                path.move(to: contactPatch)
                path.addLine(to: closestPointScreen)
            },
            with: .color(.yellow),
            lineWidth: 1.33
        )
        
        // Mark the trail measurement points
        context.fill(
            Circle().path(in: CGRect(x: contactPatch.x - 3, y: contactPatch.y - 3, width: 6, height: 6)),
            with: .color(.yellow)
        )
        context.fill(
            Circle().path(in: CGRect(x: closestPointScreen.x - 3, y: closestPointScreen.y - 3, width: 6, height: 6)),
            with: .color(.purple)
        )
        
    case .chainGrowth, .pedalKickback:
        // Chain already drawn
        break
        
    default:
        break
    }
}

// MARK: - Graph Panel

struct GraphPanel: View {
    @ObservedObject var viewModel: BikeViewModel
    @State private var selection: Int = 0
    
    var body: some View {
        TabView(selection: $selection) {
            LeverageRatioGraph(states: viewModel.analysisResults.states)
                .tabItem { Label("LR", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(0)
            
            AntiSquatGraph(states: viewModel.analysisResults.states)
                .tabItem { Label("AS", systemImage: "chart.xyaxis.line") }
                .tag(1)
            
            AntiRiseGraph(states: viewModel.analysisResults.states)
                .tabItem { Label("AR", systemImage: "chart.xyaxis.line") }
                .tag(2)
            
            PedalKickbackGraph(states: viewModel.analysisResults.states)
                .tabItem { Label("Kick", systemImage: "chart.xyaxis.line") }
                .tag(3)
            
            AxlePathGraph(states: viewModel.analysisResults.states)
                .tabItem { Label("Path", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath") }
                .tag(4)
            
            ChainGrowthGraph(states: viewModel.analysisResults.states)
                .tabItem { Label("Chain", systemImage: "chart.xyaxis.line") }
                .tag(5)
            
            WheelRateGraph(states: viewModel.analysisResults.states)
                .tabItem { Label("WR", systemImage: "chart.xyaxis.line") }
                .tag(6)
            
            TrailGraph(viewModel: viewModel)
                .tabItem { Label("Trail", systemImage: "chart.xyaxis.line") }
                .tag(7)
            
            PitchAngleGraph(viewModel: viewModel)
                .tabItem { Label("Pitch", systemImage: "angle") }
                .tag(8)
        }
        .padding()
        .onChange(of: selection) { oldValue, newValue in
            let graphs: [BikeViewModel.GraphType] = [
                .leverageRatio, .antiSquat, .antiRise, .pedalKickback,
                .axlePath, .chainGrowth, .wheelRate, .trail, .pitchAngle
            ]
            if newValue < graphs.count {
                viewModel.selectedGraph = graphs[newValue]
            }
        }
    }
}

// MARK: - Helper Views

struct NumberField: View {
    let label: String
    @Binding var value: Double
    
    init(_ label: String, value: Binding<Double>) {
        self.label = label
        self._value = value
    }
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BikeViewModel())
}

