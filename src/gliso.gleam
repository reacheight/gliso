import argv
import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/time/timestamp
import gliso/internal/intake.{type Intake, Intake}
import simplifile.{Enoent}

const usage =
  "Available commands:
take <dose> — record a medication intake (dose in mg, positive integer)
last [<n>] — show last n (optional, default = 2) records
total — show total dose taken"

const default_last_count = 2

const app = "gliso"

const records_filename = "records.csv"

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
  case read_records() {
    Ok(records) -> {
      let total_mg = records |> list.map(fn(r) { r.dose }) |> int.sum
      io.println(int.to_string(total_mg) <> " mg")
    }
    _ -> io.println("could not read records because of some file error")
  }
}

fn last(n: Int) -> Nil {
  case read_last_records(n) {
    Ok([]) -> io.println("no records yet")
    Ok(records) ->
      records |> list.map(intake.format_human) |> list.each(io.println)
    _ -> io.println("could not read records because of some file error")
  }
}

fn take(dose: Int) -> Nil {
  let record = Intake(timestamp.system_time(), dose)

  case record |> intake.format_csv |> append_record {
    Ok(_) -> io.println("successfully added the record")
    _ -> io.println("could not add the record because of some file error")
  }
}

fn get_state_dir() -> Result(String, Nil) {
  case envoy.get("XDG_STATE_HOME"), envoy.get("HOME") {
    Ok(xdg_state_home), _ if xdg_state_home != "" ->
      Ok(xdg_state_home <> "/" <> app)
    _, Ok(home) if home != "" -> Ok(home <> "/.local/state/" <> app)
    _, _ -> Error(Nil)
  }
}

fn get_records_path() -> Result(String, Nil) {
  get_state_dir() |> result.map(fn(dir) { dir <> "/" <> records_filename })
}

fn append_record(record: String) -> Result(Nil, Nil) {
  case get_state_dir() {
    Ok(state_dir) ->
      case simplifile.create_directory_all(state_dir) {
        Ok(Nil) ->
          simplifile.append(
            state_dir <> "/" <> records_filename,
            record <> "\n",
          )
          |> result.map_error(fn(_) { Nil })
        _ -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

fn read_last_records(n: Int) -> Result(List(Intake), Nil) {
  read_records()
  |> result.map(fn(records) { records |> list.reverse() |> list.take(n) })
}

fn read_records() -> Result(List(Intake), Nil) {
  case get_records_path() {
    Error(_) -> Error(Nil)
    Ok(path) ->
      case simplifile.read(path) {
        Ok(file) ->
          Ok(
            file
            |> string.trim
            |> string.split("\n")
            |> list.map(intake.parse)
            |> result.values,
          )
        Error(Enoent) -> Ok([])
        _ -> Error(Nil)
      }
  }
}

fn quote(s: String) -> String {
  "'" <> s <> "'"
}
