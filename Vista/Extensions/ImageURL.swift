import Foundation
extension String {
    var cdnURL: URL? {
        URL(string: replacingOccurrences(
            of: "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/",
            with: "https://images.sidequesttravel.co/storage/v1/object/public/"
        ))
    }

    func cdnResizedURL(width: Int, quality: Int) -> URL? {
        cdnURL
    }
}
