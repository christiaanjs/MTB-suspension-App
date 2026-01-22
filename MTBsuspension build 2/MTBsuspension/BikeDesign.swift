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

/// Represents a complete bike design with a name and geometry
struct BikeDesign: Codable {
    var name: String
    var geometry: BikeGeometry
    
    init(name: String, geometry: BikeGeometry) {
        self.name = name
        self.geometry = geometry
    }
}
