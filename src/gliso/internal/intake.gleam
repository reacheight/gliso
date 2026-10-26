import gleam/int
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}

pub type Intake {
  Intake(time: Timestamp, dose: Int)
}

pub fn format_csv(intake: Intake) -> String {
  let #(seconds, _) = intake.time |> timestamp.to_unix_seconds_and_nanoseconds()

  [
    int.to_string(seconds),
    int.to_string(intake.dose),
  ]
  |> string.join(";")
}

pub fn format_human(intake: Intake) -> String {
  let #(date, time) =
    timestamp.to_calendar(intake.time, calendar.local_offset())

  let date_part =
    int.to_string(date.day)
    <> " "
    <> calendar.month_to_string(date.month)
    <> ", "
    <> to_padded_string(time.hours)
    <> ":"
    <> to_padded_string(time.minutes)

  let dose_part = int.to_string(intake.dose) <> " mg"

  date_part <> " — " <> dose_part
}

fn to_padded_string(n: Int) -> String {
  n |> int.to_string |> string.pad_start(2, "0")
}

pub fn parse(record_string: String) -> Result(Intake, Nil) {
  case record_string |> string.split(";") {
    [seconds, dose] -> {
      use seconds <- result.try(int.parse(seconds))
      use dose <- result.try(int.parse(dose))

      Ok(Intake(timestamp.from_unix_seconds(seconds), dose))
    }
    _ -> Error(Nil)
  }
}
