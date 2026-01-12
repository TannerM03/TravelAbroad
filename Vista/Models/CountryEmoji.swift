//
//  CountryEmoji.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 6/7/25.
//

import Foundation

enum CountryEmoji: String {
    case albania = "🇦🇱"
    case andorra = "🇦🇩"
    case austria = "🇦🇹"
    case belarus = "🇧🇾"
    case belgium = "🇧🇪"
    case bosniaAndHerzegovina = "🇧🇦"
    case bulgaria = "🇧🇬"
    case croatia = "🇭🇷"
    case cyprus = "🇨🇾"
    case czechia = "🇨🇿"
    case denmark = "🇩🇰"
    case estonia = "🇪🇪"
    case finland = "🇫🇮"
    case france = "🇫🇷"
    case germany = "🇩🇪"
    case greece = "🇬🇷"
    case hungary = "🇭🇺"
    case iceland = "🇮🇸"
    case ireland = "🇮🇪"
    case italy = "🇮🇹"
    case kosovo = "🇽🇰"
    case latvia = "🇱🇻"
    case liechtenstein = "🇱🇮"
    case lithuania = "🇱🇹"
    case luxembourg = "🇱🇺"
    case malta = "🇲🇹"
    case moldova = "🇲🇩"
    case monaco = "🇲🇨"
    case montenegro = "🇲🇪"
    case morocco = "🇲🇦"
    case netherlands = "🇳🇱"
    case northMacedonia = "🇲🇰"
    case norway = "🇳🇴"
    case poland = "🇵🇱"
    case portugal = "🇵🇹"
    case romania = "🇷🇴"
    case russia = "🇷🇺"
    case sanMarino = "🇸🇲"
    case serbia = "🇷🇸"
    case slovakia = "🇸🇰"
    case slovenia = "🇸🇮"
    case spain = "🇪🇸"
    case sweden = "🇸🇪"
    case switzerland = "🇨🇭"
    case turkey = "🇹🇷"
    case ukraine = "🇺🇦"
    case unitedKingdom = "🇬🇧"
    case vaticanCity = "🇻🇦"
}

extension CountryEmoji {
    static func emoji(for country: String) -> String {
        switch country.lowercased() {
        case "albania": return CountryEmoji.albania.rawValue
        case "andorra": return CountryEmoji.andorra.rawValue
        case "austria": return CountryEmoji.austria.rawValue
        case "belarus": return CountryEmoji.belarus.rawValue
        case "belgium": return CountryEmoji.belgium.rawValue
        case "bosnia and herzegovina": return CountryEmoji.bosniaAndHerzegovina.rawValue
        case "bulgaria": return CountryEmoji.bulgaria.rawValue
        case "croatia": return CountryEmoji.croatia.rawValue
        case "cyprus": return CountryEmoji.cyprus.rawValue
        case "czechia": return CountryEmoji.czechia.rawValue
        case "denmark": return CountryEmoji.denmark.rawValue
        case "estonia": return CountryEmoji.estonia.rawValue
        case "finland": return CountryEmoji.finland.rawValue
        case "france": return CountryEmoji.france.rawValue
        case "germany": return CountryEmoji.germany.rawValue
        case "greece": return CountryEmoji.greece.rawValue
        case "hungary": return CountryEmoji.hungary.rawValue
        case "iceland": return CountryEmoji.iceland.rawValue
        case "ireland": return CountryEmoji.ireland.rawValue
        case "italy": return CountryEmoji.italy.rawValue
        case "kosovo": return CountryEmoji.kosovo.rawValue
        case "latvia": return CountryEmoji.latvia.rawValue
        case "liechtenstein": return CountryEmoji.liechtenstein.rawValue
        case "lithuania": return CountryEmoji.lithuania.rawValue
        case "luxembourg": return CountryEmoji.luxembourg.rawValue
        case "malta": return CountryEmoji.malta.rawValue
        case "moldova": return CountryEmoji.moldova.rawValue
        case "monaco": return CountryEmoji.monaco.rawValue
        case "montenegro": return CountryEmoji.montenegro.rawValue
        case "morocco": return CountryEmoji.morocco.rawValue
        case "netherlands": return CountryEmoji.netherlands.rawValue
        case "north macedonia": return CountryEmoji.northMacedonia.rawValue
        case "norway": return CountryEmoji.norway.rawValue
        case "poland": return CountryEmoji.poland.rawValue
        case "portugal": return CountryEmoji.portugal.rawValue
        case "romania": return CountryEmoji.romania.rawValue
        case "russia": return CountryEmoji.russia.rawValue
        case "san marino": return CountryEmoji.sanMarino.rawValue
        case "serbia": return CountryEmoji.serbia.rawValue
        case "slovakia": return CountryEmoji.slovakia.rawValue
        case "slovenia": return CountryEmoji.slovenia.rawValue
        case "spain": return CountryEmoji.spain.rawValue
        case "sweden": return CountryEmoji.sweden.rawValue
        case "switzerland": return CountryEmoji.switzerland.rawValue
        case "turkey": return CountryEmoji.turkey.rawValue
        case "ukraine": return CountryEmoji.ukraine.rawValue
        case "united kingdom": return CountryEmoji.unitedKingdom.rawValue
        case "vatican city": return CountryEmoji.vaticanCity.rawValue
        default: return ""
        }
    }
}
