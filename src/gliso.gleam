import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/time/timestamp
import gliso/internal/intake.{Intake}
import gliso/internal/records

const usage =
  "Available commands:
take <dose> — record a medication intake (dose in mg, positive integer)
last [<n>] — show last n (optional, default = 2) records
total — show total dose taken"

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
    _ -> io.println(usage)
  }
}

fn total() -> Nil {
  case records.read_records() {
    Ok(records) -> {
      let total_mg = records |> list.map(fn(r) { r.dose }) |> int.sum
      io.println(int.to_string(total_mg) <> " mg")
    }
    _ -> io.println("could not read records because of some file error")
  }
}

fn last(n: Int) -> Nil {
  case records.read_last_records(n) {
    Ok([]) -> io.println("no records yet")
    Ok(records) ->
      records |> list.map(intake.format_human) |> list.each(io.println)
    _ -> io.println("could not read records because of some file error")
  }
}

fn take(dose: Int) -> Nil {
  let record = Intake(timestamp.system_time(), dose)

  case record |> intake.format_csv |> records.append_record {
    Ok(_) -> io.println("successfully added the record")
    _ -> io.println("could not add the record because of some file error")
  }
}

fn quote(s: String) -> String {
  "'" <> s <> "'"
}
