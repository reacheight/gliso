import envoy
import gleam/list
import gleam/result
import gleam/string
import gliso/internal/intake.{type Intake}
import simplifile.{Enoent}

const app = "gliso"

const records_filename = "records.csv"

pub type RecordsError {
  HomeNotFound
  FileError(simplifile.FileError)
}

pub fn append_record(record: Intake) -> Result(Nil, RecordsError) {
  use records_path <- result.try(ensure_records_path())

  simplifile.append(
    to: records_path,
    contents: intake.format_csv(record) <> "\n",
  )
  |> result.map_error(FileError)
}

pub fn read_last_records(n: Int) -> Result(List(Intake), RecordsError) {
  read_records()
  |> result.map(fn(records) { records |> list.reverse() |> list.take(n) })
}

pub fn read_records() -> Result(List(Intake), RecordsError) {
  use records_path <- result.try(get_records_path())

  case simplifile.read(records_path) {
    Ok(file) ->
      file
      |> string.trim
      |> string.split("\n")
      |> list.map(intake.parse)
      |> result.values
      |> Ok
    Error(Enoent) -> Ok([])
    Error(err) -> FileError(err) |> Error
  }
}

pub fn get_records_path() -> Result(String, RecordsError) {
  get_state_dir() |> result.map(fn(dir) { dir <> "/" <> records_filename })
}

fn ensure_records_path() -> Result(String, RecordsError) {
  use dir <- result.try(get_state_dir())

  simplifile.create_directory_all(dir)
  |> result.replace(dir <> "/" <> records_filename)
  |> result.map_error(FileError)
}

fn get_state_dir() -> Result(String, RecordsError) {
  case envoy.get("XDG_STATE_HOME"), envoy.get("HOME") {
    Ok(xdg_state_home), _ if xdg_state_home != "" ->
      Ok(xdg_state_home <> "/" <> app)
    _, Ok(home) if home != "" -> Ok(home <> "/.local/state/" <> app)
    _, _ -> Error(HomeNotFound)
  }
}
