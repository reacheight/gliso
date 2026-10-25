import gleam/int
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}

pub type Record {
  Record(time: Timestamp, dose: Int)
}

pub fn format_csv(record: Record) -> String {
  let #(seconds, _) = record.time |> timestamp.to_unix_seconds_and_nanoseconds()

  [
    int.to_string(seconds),
    int.to_string(record.dose),
  ]
  |> string.join(";")
}

pub fn format_human(record: Record) -> String {
  let #(date, time) =
    timestamp.to_calendar(record.time, calendar.local_offset())

  let date_part =
    int.to_string(date.day)
    <> " "
    <> calendar.month_to_string(date.month)
    <> ", "
    <> int.to_string(time.hours)
    <> ":"
    <> int.to_string(time.minutes)

  let dose_part = int.to_string(record.dose) <> " mg"

  date_part <> " — " <> dose_part
}

pub fn parse(record_string: String) -> Result(Record, Nil) {
  case record_string |> string.split(";") {
    [seconds, dose] -> {
      use seconds <- result.try(int.parse(seconds))
      use dose <- result.try(int.parse(dose))

      Ok(Record(timestamp.from_unix_seconds(seconds), dose))
    }
    _ -> Error(Nil)
  }
}
