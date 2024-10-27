import gleam
import gleam/result
import simplifile.{type FileError}
import snag.{type Result}

/// map `Result` with `FileError` to `snag.Result`
pub fn map_file_error(
  res: gleam.Result(a, FileError),
  context: String,
) -> Result(a) {
  res
  |> result.map_error(fn(err) { err |> simplifile.describe_error |> snag.new })
  |> snag.context(context)
}
