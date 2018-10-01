import NIO

extension PostgresConnection {
    public func simpleQuery(_ string: String) -> EventLoopFuture<[PostgresRow]> {
        var rows: [PostgresRow] = []
        return simpleQuery(string) { rows.append($0) }.map { rows }
    }
    
    public func simpleQuery(_ string: String, _ onRow: @escaping (PostgresRow) -> ()) -> EventLoopFuture<Void> {
        var info: PostgresMessage.RowDescription?
        return handler.send([.simpleQuery(.init(string: string))]) { message in
            switch message {
            case .dataRow(let data):
                guard let fields = info?.fields else { fatalError() }
                onRow(PostgresRow(fields: fields, columns: data.columns))
                return false
            case .rowDescription(let r):
                info = r
                return false
            case .commandComplete(let complete):
                return false
            case .readyForQuery:
                return true
            default: throw PostgresError(.protocol("Unexpected message during simple query: \(message)"))
            }
        }
    }
}