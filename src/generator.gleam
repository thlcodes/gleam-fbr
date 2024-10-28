import errors
import gleam/result
import simplifile
import snag.{type Result}
import types.{type Route}

const initial_template = "import wisp

// _FBR_IMPORTS_START
// _FBR_IMPORTS_END

pub fn router(req: wisp.Request) -> wisp.Response {
  case req.method, wisp.path_segments(req) {
    // _FBR_ROUTES_START_
    // _FBR_ROUTES_END_
    _, _ -> not_found()
  }
}

fn not_found() -> wisp.Response {
  wisp.not_found() |> wisp.string_body(\"not_found\")
}
"

pub fn generate(from _routes: List(Route), into file: String) -> Result(String) {
  use current_content <- result.try(case simplifile.read(file) {
    Ok(content) -> Ok(content)
    Error(simplifile.Enoent) -> Ok(initial_template)
    Error(err) -> errors.map_file_error(Error(err), "could not read " <> file)
  })
  Ok(current_content)
}

fn was_generated_by_fbr(content: String) -> Bool {
  False
}
