import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/time/timestamp
import gliso/internal/intake.{Intake}
import gliso/internal/records.{type RecordsError, FileError, HomeNotFound}
import simplifile

const usage =
  "Available commands:
take <dose> — record a medication intake (dose in mg, positive integer)
last [<n>] — show last n (optional, default = 2) records
total — show total dose taken alltime
file — show records file path"

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
    ["last"] -> last(default_last_count)
    ["last", n] ->
      case int.parse(n) {
        Ok(n) if n > 0 -> last(n)
        _ -> io.println("<n> should be a positive integer, was " <> quote(n))
      }
    ["total"] -> total()
    ["file"] ->
      case records.get_records_path() {
        Ok(path) -> path
        Error(err) -> get_error_message(err)
      }
      |> io.println
    _ -> io.println(usage)
  }
}

fn total() -> Nil {
  case records.read_records() {
    Ok(records) -> {
      let total_mg = records |> list.map(fn(r) { r.dose }) |> int.sum
      int.to_string(total_mg) <> " mg"
    }
    Error(err) -> "could not read records: " <> get_error_message(err)
  }
  |> io.println
}

fn last(n: Int) -> Nil {
  case records.read_last_records(n) {
    Ok([]) -> "no records yet"
    Ok(records) -> records |> list.map(intake.format_human) |> string.join("\n")
    Error(err) -> "could not read records: " <> get_error_message(err)
  }
  |> io.println
}

fn take(dose: Int) -> Nil {
  let record = Intake(timestamp.system_time(), dose)

  case record |> records.append_record {
    Ok(_) -> "successfully added the record"
    Error(err) -> "could not add the record: " <> get_error_message(err)
  }
  |> io.println
}

fn get_error_message(err: RecordsError) -> String {
  case err {
    HomeNotFound ->
      "could not find home env var to create the records file (searched 'XDG_STATE_HOME' and 'HOME')"
    FileError(err) -> "file error: " <> simplifile.describe_error(err)
  }
}

fn quote(s: String) -> String {
  "'" <> s <> "'"
}
