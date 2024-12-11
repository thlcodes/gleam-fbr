pub const routes_folder = "/src/routes"

pub const router_file = "/src/router.gleam"

pub const initial_template = "import wisp
import gleam_http

// _FBR_IMPORTS_BEGIN_
// _FBR_IMPORTS_END_

pub fn router(req: wisp.Request) -> wisp.Response {
  case req.method, wisp.path_segments(req) {
    // _FBR_ROUTES_BEGIN_
    // _FBR_ROUTES_END_
    _, _ -> not_found()
  }
}

fn not_found() -> wisp.Response {
  wisp.not_found() |> wisp.string_body(\"not_found\")
}
"
