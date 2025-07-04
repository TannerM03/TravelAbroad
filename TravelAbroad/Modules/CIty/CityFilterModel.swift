//
//  CityFilter.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/10/25.
//

import Foundation

enum CityFilter: String, CaseIterable, Identifiable {
    case best, worst, none

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .best: return "arrow.up.to.line"
        case .worst: return "arrow.down.to.line"
        case .none: return "line.horizontal.3.decrease.circle"
        }
    }

    var label: String {
        switch self {
        case .best: return "High -> Low"
        case .worst: return "Low -> High"
        case .none: return "No filter"
        }
    }
}
