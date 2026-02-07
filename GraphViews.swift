//
//  GraphViews.swift
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
import Charts

// MARK: - Leverage Ratio Graph

struct LeverageRatioGraph: View {
    let states: [KinematicState]
    @State private var selectedTravel: Double?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Leverage Ratio")
                .font(.headline)
                .padding(.leading)
            
            if states.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(states, id: \.travelMM) { state in
                    LineMark(
                        x: .value("Travel", state.travelMM),
                        y: .value("LR", state.leverageRatio)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        RuleMark(x: .value("Selected", selectedTravel))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Travel", selectedState.travelMM),
                            y: .value("LR", selectedState.leverageRatio)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Wheel Travel (mm)", alignment: .center)
                .chartYAxisLabel("Leverage Ratio", alignment: .center)
                .chartYScale(domain: 1.5...4.0)
                .chartXSelection(value: $selectedTravel)
                .padding()
                
                // Fixed height tooltip area to prevent graph jumping
                HStack {
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        Text("Travel: \(String(format: "%.1f", selectedState.travelMM))mm, LR: \(String(format: "%.2f", selectedState.leverageRatio))")
                            .font(.caption)
                    } else {
                        Text(" ")  // Placeholder to maintain height
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Anti-Squat Graph

struct AntiSquatGraph: View {
    let states: [KinematicState]
    @State private var selectedTravel: Double?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Anti-Squat")
                .font(.headline)
                .padding(.leading)
            
            if states.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(states, id: \.travelMM) { state in
                        LineMark(
                            x: .value("Travel", state.travelMM),
                            y: .value("AS%", state.antiSquat)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                    }
                    
                    // 100% reference line
                    RuleMark(y: .value("100%", 100))
                        .foregroundStyle(.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        RuleMark(x: .value("Selected", selectedTravel))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Travel", selectedState.travelMM),
                            y: .value("AS%", selectedState.antiSquat)
                        )
                        .foregroundStyle(.green)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Wheel Travel (mm)", alignment: .center)
                .chartYAxisLabel("Anti-Squat (%)", alignment: .center)
                .chartXSelection(value: $selectedTravel)
                .padding()
                
                // Fixed height tooltip area to prevent graph jumping
                HStack {
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        Text("Travel: \(String(format: "%.1f", selectedState.travelMM))mm, AS: \(String(format: "%.0f", selectedState.antiSquat))%")
                            .font(.caption)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Anti-Rise Graph

struct AntiRiseGraph: View {
    let states: [KinematicState]
    @State private var selectedTravel: Double?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Anti-Rise")
                .font(.headline)
                .padding(.leading)
            
            if states.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(states, id: \.travelMM) { state in
                    LineMark(
                        x: .value("Travel", state.travelMM),
                        y: .value("AR%", state.antiRise)
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        RuleMark(x: .value("Selected", selectedTravel))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Travel", selectedState.travelMM),
                            y: .value("AR%", selectedState.antiRise)
                        )
                        .foregroundStyle(.orange)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Wheel Travel (mm)", alignment: .center)
                .chartYAxisLabel("Anti-Rise (%)", alignment: .center)
                .chartXSelection(value: $selectedTravel)
                .padding()
                
                // Fixed height tooltip area to prevent graph jumping
                HStack {
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        Text("Travel: \(String(format: "%.1f", selectedState.travelMM))mm, AR: \(String(format: "%.0f", selectedState.antiRise))%")
                            .font(.caption)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Pedal Kickback Graph

struct PedalKickbackGraph: View {
    let states: [KinematicState]
    @State private var selectedTravel: Double?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Pedal Kickback")
                .font(.headline)
                .padding(.leading)
            
            if states.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(states, id: \.travelMM) { state in
                    LineMark(
                        x: .value("Travel", state.travelMM),
                        y: .value("Degrees", state.pedalKickback)
                    )
                    .foregroundStyle(.red)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        RuleMark(x: .value("Selected", selectedTravel))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Travel", selectedState.travelMM),
                            y: .value("Degrees", selectedState.pedalKickback)
                        )
                        .foregroundStyle(.red)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Wheel Travel (mm)", alignment: .center)
                .chartYAxisLabel("Pedal Kickback (degrees)", alignment: .center)
                .chartXSelection(value: $selectedTravel)
                .padding()
                
                // Fixed height tooltip area to prevent graph jumping
                HStack {
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        Text("Travel: \(String(format: "%.1f", selectedState.travelMM))mm, Kickback: \(String(format: "%.1f", selectedState.pedalKickback))°")
                            .font(.caption)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Axle Path Graph

struct AxlePathGraph: View {
    let states: [KinematicState]
    @State private var selectedX: Double?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Rear Axle Path")
                .font(.headline)
                .padding(.leading)
            
            if states.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(states, id: \.travelMM) { state in
                    LineMark(
                        x: .value("Horizontal", state.rearAxlePosition.x),
                        y: .value("Vertical", state.rearAxlePosition.y)
                    )
                    .foregroundStyle(.purple)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedX = selectedX,
                       let selectedState = states.first(where: { abs($0.rearAxlePosition.x - selectedX) < 1.0 }) {
                        RuleMark(x: .value("Selected", selectedX))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Horizontal", selectedState.rearAxlePosition.x),
                            y: .value("Vertical", selectedState.rearAxlePosition.y)
                        )
                        .foregroundStyle(.purple)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Horizontal Position (mm)", alignment: .center)
                .chartYAxisLabel("Vertical Position (mm)", alignment: .center)
                .chartXSelection(value: $selectedX)
                .padding()
                
                // Fixed height tooltip area to prevent graph jumping
                HStack {
                    if let selectedX = selectedX,
                       let selectedState = states.first(where: { abs($0.rearAxlePosition.x - selectedX) < 1.0 }) {
                        Text("X: \(String(format: "%.1f", selectedState.rearAxlePosition.x))mm, Y: \(String(format: "%.1f", selectedState.rearAxlePosition.y))mm, Travel: \(String(format: "%.1f", selectedState.travelMM))mm")
                            .font(.caption)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Chain Growth Graph

struct ChainGrowthGraph: View {
    let states: [KinematicState]
    @State private var selectedTravel: Double?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Chain Growth")
                .font(.headline)
                .padding(.leading)
            
            if states.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(states, id: \.travelMM) { state in
                    LineMark(
                        x: .value("Travel", state.travelMM),
                        y: .value("Growth (mm)", state.totalChainGrowth)
                    )
                    .foregroundStyle(.cyan)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        RuleMark(x: .value("Selected", selectedTravel))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Travel", selectedState.travelMM),
                            y: .value("Growth (mm)", selectedState.totalChainGrowth)
                        )
                        .foregroundStyle(.cyan)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Wheel Travel (mm)", alignment: .center)
                .chartYAxisLabel("Total Chain Growth (mm)", alignment: .center)
                .chartXSelection(value: $selectedTravel)
                .padding()
                
                // Fixed height tooltip area to prevent graph jumping
                HStack {
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        Text("Travel: \(String(format: "%.1f", selectedState.travelMM))mm, Growth: \(String(format: "%.2f", selectedState.totalChainGrowth))mm")
                            .font(.caption)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Wheel Rate Graph

struct WheelRateGraph: View {
    let states: [KinematicState]
    @State private var selectedTravel: Double?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Wheel Rate")
                .font(.headline)
                .padding(.leading)
            
            if states.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(states, id: \.travelMM) { state in
                    LineMark(
                        x: .value("Travel", state.travelMM),
                        y: .value("Trail (mm)", state.wheelRate)
                    )
                    .foregroundStyle(.pink)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        RuleMark(x: .value("Selected", selectedTravel))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Travel", selectedState.travelMM),
                            y: .value("Trail (mm)", selectedState.wheelRate)
                        )
                        .foregroundStyle(.pink)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Wheel Travel (mm)", alignment: .center)
                .chartYAxisLabel("Wheel Trail (mm)", alignment: .center)
                .chartXSelection(value: $selectedTravel)
                .padding()
                
                // Fixed height tooltip area to prevent graph jumping
                HStack {
                    if let selectedTravel = selectedTravel,
                       let selectedState = states.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        Text("Travel: \(String(format: "%.1f", selectedState.travelMM))mm, Rate: \(String(format: "%.1f", selectedState.wheelRate)) N/mm")
                            .font(.caption)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Trail Graph

struct TrailGraph: View {
    @ObservedObject var viewModel: BikeViewModel
    @State private var selectedTravel: Double?
    
    // Calculate live states with current fork compression
    private var liveStates: [KinematicState] {
        guard !viewModel.analysisResults.states.isEmpty else { return [] }
        
        return viewModel.analysisResults.states.map { baseState in
            // Calculate the shock stroke that produced this state
            let shockStroke = viewModel.geometry.shockETE - baseState.shockLength
            
            // Calculate proportional fork compression for this shock position
            let shockRatio = shockStroke / viewModel.geometry.shockStroke
            let forkStroke = viewModel.slidersLinked ? (shockRatio * viewModel.geometry.forkTravel) : viewModel.currentForkStroke
            
            // Get recalculated state with current fork setting
            if let state = viewModel.getStateAt(shockStroke: shockStroke, forkStroke: forkStroke) {
                return state
            } else {
                return baseState
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Trail")
                .font(.headline)
                .padding(.leading)
            
            if liveStates.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(liveStates, id: \.travelMM) { state in
                    LineMark(
                        x: .value("Travel", state.travelMM),
                        y: .value("Trail (mm)", state.trail)
                    )
                    .foregroundStyle(.red)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedTravel = selectedTravel,
                       let selectedState = liveStates.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        RuleMark(x: .value("Selected", selectedTravel))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Travel", selectedState.travelMM),
                            y: .value("Trail (mm)", selectedState.trail)
                        )
                        .foregroundStyle(.red)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Wheel Travel (mm)", alignment: .center)
                .chartYAxisLabel("Trail (mm)", alignment: .center)
                .chartXSelection(value: $selectedTravel)
                .padding()
                
                // Fixed height tooltip area to prevent graph jumping
                HStack {
                    if let selectedTravel = selectedTravel,
                       let selectedState = liveStates.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        Text("Travel: \(String(format: "%.1f", selectedState.travelMM))mm, Trail: \(String(format: "%.1f", selectedState.trail)) mm")
                            .font(.caption)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Pitch Angle Graph

struct PitchAngleGraph: View {
    @ObservedObject var viewModel: BikeViewModel
    @State private var selectedTravel: Double?
    
    // Calculate live states with current fork compression
    private var liveStates: [KinematicState] {
        guard !viewModel.analysisResults.states.isEmpty else { return [] }
        
        return viewModel.analysisResults.states.map { baseState in
            // Calculate the shock stroke that produced this state
            let shockStroke = viewModel.geometry.shockETE - baseState.shockLength
            
            // Calculate proportional fork compression for this shock position
            let shockRatio = shockStroke / viewModel.geometry.shockStroke
            let forkStroke = viewModel.slidersLinked ? (shockRatio * viewModel.geometry.forkTravel) : viewModel.currentForkStroke
            
            // Get recalculated state with current fork setting
            if let state = viewModel.getStateAt(shockStroke: shockStroke, forkStroke: forkStroke) {
                return state
            } else {
                return baseState
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Bike Pitch Angle")
                .font(.headline)
                .padding(.leading)
            
            if liveStates.isEmpty {
                Text("No data - press Calculate")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(liveStates, id: \.travelMM) { state in
                    LineMark(
                        x: .value("Travel", state.travelMM),
                        y: .value("Pitch", state.pitchAngleDegrees)
                    )
                    .foregroundStyle(.purple)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedTravel = selectedTravel,
                       let selectedState = liveStates.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        RuleMark(x: .value("Selected", selectedTravel))
                            .foregroundStyle(.gray.opacity(0.5))
                        PointMark(
                            x: .value("Travel", selectedState.travelMM),
                            y: .value("Pitch", selectedState.pitchAngleDegrees)
                        )
                        .foregroundStyle(.purple)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Wheel Travel (mm)", alignment: .center)
                .chartYAxisLabel("Pitch Angle (°)", alignment: .center)
                .chartXSelection(value: $selectedTravel)
                .padding()
                
                // Fixed height tooltip area
                HStack {
                    if let selectedTravel = selectedTravel,
                       let selectedState = liveStates.first(where: { abs($0.travelMM - selectedTravel) < 0.5 }) {
                        let direction = selectedState.pitchAngleDegrees > 0 ? "nose down ↓" : (selectedState.pitchAngleDegrees < 0 ? "nose up ↑" : "level —")
                        Text("Travel: \(String(format: "%.1f", selectedState.travelMM))mm, Pitch: \(String(format: "%.2f", abs(selectedState.pitchAngleDegrees)))° \(direction)")
                            .font(.caption)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
        }
    }
}
