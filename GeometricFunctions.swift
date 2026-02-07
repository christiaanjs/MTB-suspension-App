//
//  geometryFunctions.swift
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

// MARK: - Geometric Utility Functions

/// Calculate distance between two points
func distance(_ p1: Point2D, _ p2: Point2D) -> Double {
    let dx = p2.x - p1.x
    let dy = p2.y - p1.y
    return sqrt(dx * dx + dy * dy)
}

/// Calculate angle from p1 to p2 (in radians)
func angle(from p1: Point2D, to p2: Point2D) -> Double {
    let dx = p2.x - p1.x
    let dy = p2.y - p1.y
    return atan2(dy, dx)
}

/// Find intersection of two lines defined by two points each
/// Returns nil if lines are parallel
func lineIntersection(line1Point1: Point2D, line1Point2: Point2D, 
                      line2Point1: Point2D, line2Point2: Point2D) -> Point2D? {
    let x1 = line1Point1.x, y1 = line1Point1.y
    let x2 = line1Point2.x, y2 = line1Point2.y
    let x3 = line2Point1.x, y3 = line2Point1.y
    let x4 = line2Point2.x, y4 = line2Point2.y
    
    let denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    
    if abs(denom) < 0.0001 {
        return nil  // Lines are parallel
    }
    
    let t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
    
    return Point2D(
        x: x1 + t * (x2 - x1),
        y: y1 + t * (y2 - y1)
    )
}

/// Rotate a point around a pivot by given angle (in radians)
func rotate(_ point: Point2D, around pivot: Point2D, by angleRad: Double) -> Point2D {
    let dx = point.x - pivot.x
    let dy = point.y - pivot.y
    
    let rotatedX = dx * cos(angleRad) - dy * sin(angleRad)
    let rotatedY = dx * sin(angleRad) + dy * cos(angleRad)
    
    return Point2D(x: pivot.x + rotatedX, y: pivot.y + rotatedY)
}

/// Calculate chain length between two sprockets using tangent method
func calculateChainLength(
    from chainring: Point2D,
    to cog: Point2D,
    chainringRadius: Double,
    cogRadius: Double
) -> Double {
    let centerDist = distance(chainring, cog)
    
    if centerDist < abs(chainringRadius - cogRadius) {
        return centerDist
    }
    
    let radiusDiff = chainringRadius - cogRadius
    let tangentLength = sqrt(centerDist * centerDist - radiusDiff * radiusDiff)
    
    let alpha = asin(radiusDiff / centerDist)
    let chainringWrap = .pi + alpha
    let cogWrap = .pi - alpha
    
    let chainringArc = chainringRadius * chainringWrap
    let cogArc = cogRadius * cogWrap
    
    return tangentLength + chainringArc + cogArc
}

/// Calculate sprocket radius from tooth count
func sprocketRadius(teeth: Int) -> Double {
    let pitch = 12.7  // mm (standard chain pitch)
    return (Double(teeth) * pitch) / (2.0 * .pi)
}

/// Convert degrees to radians
func degreesToRadians(_ degrees: Double) -> Double {
    degrees * .pi / 180.0
}

/// Convert radians to degrees
func radiansToDegrees(_ radians: Double) -> Double {
    radians * 180.0 / .pi
}

/// Calculate anti-squat percentage - matches what the overlay draws
func calculateVisualAntiSquat(state: KinematicState, geometry: BikeGeometry) -> Double {
    // Use world coordinates directly (no pitch rotation)
    let chainringRadius = sprocketRadius(teeth: geometry.chainringTeeth)
    let cogRadius = sprocketRadius(teeth: geometry.cogTeeth)
    
    // Calculate chain line based on idler configuration
    let chainLineStart: Point2D
    let chainLineEnd: Point2D
    
    if geometry.idlerType == .none {
        // No idler: chainring to cog
        let chainringCenter = Point2D(x: state.bbPosition.x + geometry.chainringOffsetX, 
                                     y: state.bbPosition.y + geometry.chainringOffsetY)
        let cogCenter = state.rearAxlePosition
        
        let dx = cogCenter.x - chainringCenter.x
        let dy = cogCenter.y - chainringCenter.y
        let dist = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        let radiusDiff = chainringRadius - cogRadius
        let tangentAngle = asin(radiusDiff / dist)
        
        let upperAngle = angle + tangentAngle
        chainLineStart = Point2D(
            x: chainringCenter.x + chainringRadius * sin(upperAngle),
            y: chainringCenter.y - chainringRadius * cos(upperAngle)
        )
        chainLineEnd = Point2D(
            x: cogCenter.x + cogRadius * sin(upperAngle),
            y: cogCenter.y - cogRadius * cos(upperAngle)
        )
        
    } else if geometry.idlerType == .frameMounted {
        // Frame-mounted: idler to cog
        let idlerCenter = Point2D(x: state.bbPosition.x + geometry.idlerX, 
                                 y: state.bbPosition.y + geometry.idlerY)
        let cogCenter = state.rearAxlePosition
        let idlerRadius = sprocketRadius(teeth: geometry.idlerTeeth)
        
        let dx = cogCenter.x - idlerCenter.x
        let dy = cogCenter.y - idlerCenter.y
        let dist = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        let radiusDiff = idlerRadius - cogRadius
        let tangentAngle = asin(radiusDiff / dist)
        
        let upperAngle = angle + tangentAngle
        chainLineStart = Point2D(
            x: idlerCenter.x + idlerRadius * sin(upperAngle),
            y: idlerCenter.y - idlerRadius * cos(upperAngle)
        )
        chainLineEnd = Point2D(
            x: cogCenter.x + cogRadius * sin(upperAngle),
            y: cogCenter.y - cogRadius * cos(upperAngle)
        )
        
    } else {
        // Swingarm-mounted: chainring to idler
        let topOutIdlerX = geometry.idlerX - geometry.bbToPivotX
        let topOutIdlerY = (geometry.bbHeight + geometry.idlerY) - (geometry.bbHeight + geometry.bbToPivotY)
        
        let topOutPivot = Point2D(x: geometry.bbToPivotX, y: geometry.bbHeight + geometry.bbToPivotY)
        let topOutVertDist = geometry.rearWheelRadius - topOutPivot.y
        let topOutHorizDist = sqrt(geometry.swingarmLength * geometry.swingarmLength - topOutVertDist * topOutVertDist)
        let topOutAxle = Point2D(x: topOutPivot.x - topOutHorizDist, y: geometry.rearWheelRadius)
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
        
        let chainringCenter = Point2D(x: state.bbPosition.x + geometry.chainringOffsetX, 
                                     y: state.bbPosition.y + geometry.chainringOffsetY)
        let idlerRadius = sprocketRadius(teeth: geometry.idlerTeeth)
        
        let dx = idlerCenter.x - chainringCenter.x
        let dy = idlerCenter.y - chainringCenter.y
        let dist = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        let radiusDiff = chainringRadius - idlerRadius
        let tangentAngle = asin(radiusDiff / dist)
        
        let upperAngle = angle + tangentAngle
        chainLineStart = Point2D(
            x: chainringCenter.x + chainringRadius * sin(upperAngle),
            y: chainringCenter.y - chainringRadius * cos(upperAngle)
        )
        chainLineEnd = Point2D(
            x: idlerCenter.x + idlerRadius * sin(upperAngle),
            y: idlerCenter.y - idlerRadius * cos(upperAngle)
        )
    }
    
    // Find IFC (intersection of IC-to-rear-axle line with chain line)
    guard let ifc = lineIntersection(
        line1Point1: state.pivotPosition,
        line1Point2: state.rearAxlePosition,
        line2Point1: chainLineStart,
        line2Point2: chainLineEnd
    ) else {
        return 0.0
    }
    
    // Find AS intersection (rear contact through IFC to front vertical)
    let rearContactWorld = Point2D(x: state.rearAxlePosition.x, y: 0)
    let frontContactWorld = Point2D(x: state.frontAxlePosition.x, y: 0)
    let frontContactTop = Point2D(x: state.frontAxlePosition.x, y: 10000)
    
    guard let asIntersection = lineIntersection(
        line1Point1: rearContactWorld,
        line1Point2: ifc,
        line2Point1: frontContactWorld,
        line2Point2: frontContactTop
    ) else {
        return 0.0
    }
    
    // Calculate percentage
    let comHeight = state.bbPosition.y + geometry.comY
    return (asIntersection.y / comHeight) * 100.0
}

/// Calculate anti-rise percentage - matches what the overlay draws
func calculateVisualAntiRise(state: KinematicState, geometry: BikeGeometry) -> Double {
    // Use world coordinates directly (no pitch rotation)
    let rearContactWorld = Point2D(x: state.rearAxlePosition.x, y: 0)
    let frontContactWorld = Point2D(x: state.frontAxlePosition.x, y: 0)
    let frontContactTop = Point2D(x: state.frontAxlePosition.x, y: 10000)
    
    // Find AR intersection (rear contact through IC to front vertical)
    guard let arIntersection = lineIntersection(
        line1Point1: rearContactWorld,
        line1Point2: state.pivotPosition,
        line2Point1: frontContactWorld,
        line2Point2: frontContactTop
    ) else {
        return 0.0
    }
    
    // COM horizontal line intersection with front vertical
    let comPosition = Point2D(x: state.bbPosition.x + geometry.comX, y: state.bbPosition.y + geometry.comY)
    guard let comIntersection = lineIntersection(
        line1Point1: comPosition,
        line1Point2: Point2D(x: comPosition.x + 1000, y: comPosition.y),
        line2Point1: frontContactWorld,
        line2Point2: frontContactTop
    ) else {
        return 0.0
    }
    
    // Calculate percentage
    return (arIntersection.y / comIntersection.y) * 100.0
}

/// Linear interpolation between two values
func lerp(from a: Double, to b: Double, t: Double) -> Double {
    a + (b - a) * t
}

/// Linear interpolation between two points
func lerp(from p1: Point2D, to p2: Point2D, t: Double) -> Point2D {
    Point2D(
        x: lerp(from: p1.x, to: p2.x, t: t),
        y: lerp(from: p1.y, to: p2.y, t: t)
    )
}

/// Find intersection points of two circles
func circleCircleIntersection(
    center1: Point2D,
    radius1: Double,
    center2: Point2D,
    radius2: Double
) -> [Point2D] {
    let d = distance(center1, center2)
    
    if d > radius1 + radius2 { return [] }
    if d < abs(radius1 - radius2) { return [] }
    if d == 0 && radius1 == radius2 { return [] }
    
    let a = (radius1 * radius1 - radius2 * radius2 + d * d) / (2 * d)
    let h = sqrt(radius1 * radius1 - a * a)
    
    let p2 = Point2D(
        x: center1.x + a * (center2.x - center1.x) / d,
        y: center1.y + a * (center2.y - center1.y) / d
    )
    
    let intersection1 = Point2D(
        x: p2.x + h * (center2.y - center1.y) / d,
        y: p2.y - h * (center2.x - center1.x) / d
    )
    
    let intersection2 = Point2D(
        x: p2.x - h * (center2.y - center1.y) / d,
        y: p2.y + h * (center2.x - center1.x) / d
    )
    
    if h < 0.001 {
        return [p2]
    }
    
    return [intersection1, intersection2]
}

/// Apply pitch rotation to a point around rear axle (for display only)
func applyPitch(_ point: Point2D, pitchRad: Double, rearAxle: Point2D) -> Point2D {
    let dx = point.x - rearAxle.x
    let dy = point.y - rearAxle.y
    let cosP = cos(-pitchRad)
    let sinP = sin(-pitchRad)
    return Point2D(
        x: rearAxle.x + dx * cosP - dy * sinP,
        y: rearAxle.y + dx * sinP + dy * cosP
    )
}
