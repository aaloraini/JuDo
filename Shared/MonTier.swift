import Foundation

struct MonTier: Identifiable {
    let id: String
    let monAmount: Int

    var label: String { "\(monAmount) Mon" }

    static let all: [MonTier] = [
        .init(id: "com.judo.mon",      monAmount: 1),
        .init(id: "com.judo.mon.5",    monAmount: 5),
        .init(id: "com.judo.mon.10",   monAmount: 10),
        .init(id: "com.judo.mon.50",   monAmount: 50),
        .init(id: "com.judo.mon.100",  monAmount: 100),
    ]
}
