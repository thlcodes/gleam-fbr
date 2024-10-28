import wisp

pub fn router(req: wisp.Request) -> wisp.Response {
  case req.method, wisp.path_segments(req) {
    _, _ -> not_found()
  }
}

fn not_found() -> wisp.Response {
  wisp.not_found() |> wisp.string_body("not_found")
}
