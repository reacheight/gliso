import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/time/timestamp
import record.{type Record, Record}
import simplifile.{type FileError, Enoent}

const usage =
  "Available commands:
take <dose> — record a medication intake (dose in mg, positive integer)
last [<n>] — show last n (optional, default = 2) records"

const default_last_count = 2

pub fn main() -> Nil {
  case argv.load().arguments {
    ["take", dose] ->
      case int.parse(dose) {
        Ok(dose) if dose > 0 -> take(dose)
        _ ->
          io.println(
            "<dose> should be a positive integer (dose in mg), was "
            <> quote(dose),
          )
      }
    ["last"] -> last(2)
    ["last", n] ->
      case int.parse(n) {
        Ok(n) if n > 0 -> last(default_last_count)
        _ -> io.println("<n> should be a positive integer, was " <> quote(n))
      }
    _ -> io.println(usage)
  }
}

fn last(n: Int) -> Nil {
  case read_last_records(n) {
    Ok([]) -> io.println("no records yet")
    Ok(records) ->
      records |> list.map(record.format_human) |> list.each(io.println)
    _ -> io.println("could not read records because of some file error")
  }
}

fn take(dose: Int) -> Nil {
  let record = Record(timestamp.system_time(), dose)

  case record |> record.format_csv |> append_record {
    Ok(_) -> io.println("successfully added the record")
    _ -> io.println("could not add the record because of some file error")
  }
}

const records_filename = "records.csv"

fn append_record(record: String) -> Result(Nil, FileError) {
  simplifile.append(records_filename, record <> "\n")
}

fn read_last_records(n: Int) -> Result(List(Record), Nil) {
  read_records()
  |> result.map(fn(records) { records |> list.reverse() |> list.take(n) })
}

fn read_records() -> Result(List(Record), Nil) {
  case simplifile.read(records_filename) {
    Ok(file) ->
      file
      |> string.trim
      |> string.split("\n")
      |> list.map(record.parse)
      |> result.all
    Error(Enoent) -> Ok([])
    _ -> Error(Nil)
  }
}

fn quote(s: String) -> String {
  "'" <> s <> "'"
}
