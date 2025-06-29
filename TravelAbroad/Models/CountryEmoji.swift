//
//  CountryEmoji.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/7/25.
//

import Foundation

enum CountryEmoji: String {
    case italy = "🇮🇹"
    case spain = "🇪🇸"
    case france = "🇫🇷"
    case greece = "🇬🇷"
    case switzerland = "🇨🇭"
    case croatia = "🇭🇷"
    case netherlands = "🇳🇱"
    case iceland = "🇮🇸"
    case germany = "🇩🇪"
    case morocco = "🇲🇦"
    case czechia = "🇨🇿"
    case portugal = "🇵🇹"
}

extension CountryEmoji {
    static func emoji(for country: String) -> String {
        switch country.lowercased() {
        case "italy": return CountryEmoji.italy.rawValue
        case "france": return CountryEmoji.france.rawValue
        case "spain": return CountryEmoji.spain.rawValue
        case "greece": return CountryEmoji.greece.rawValue
        case "switzerland": return CountryEmoji.switzerland.rawValue
        case "croatia": return CountryEmoji.croatia.rawValue
        case "netherlands": return CountryEmoji.netherlands.rawValue
        case "iceland": return CountryEmoji.iceland.rawValue
        case "germany": return CountryEmoji.germany.rawValue
        case "morocco": return CountryEmoji.morocco.rawValue
        case "czechia": return CountryEmoji.czechia.rawValue
        case "portugal": return CountryEmoji.portugal.rawValue


        default: return ""
        }
    }
}

