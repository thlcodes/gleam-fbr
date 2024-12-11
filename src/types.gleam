import gleam/http
import gleam/int
import gleam/list
import gleam/string

pub type Route {
  Route(file: String, line: Int, method: Method, path: Path, has_context: Bool)
  InvalidRoute(file: String, line: Int, reson: String)
}

pub type Path =
  List(PathSegment)

pub type PathSegment {
  Index
  Static(String)
  Variable(String)
  Rest(String)
}

pub type Method {
  Method(http.Method)
  AnyMethod
}

// to_string functions

pub fn path_to_string(path: Path) -> String {
  "/"
  <> path
  |> list.filter_map(fn(segment) {
    case segment {
      Index -> Error(Nil)
      Static(s) -> Ok(s)
      Variable(v) -> Ok("[" <> v <> "]")
      Rest(r) -> Ok(r <> "...")
    }
  })
  |> string.join("/")
}

pub fn method_to_string(method: Method) -> String {
  case method {
    Method(m) -> http.method_to_string(m) |> string.uppercase
    AnyMethod -> "ANY"
  }
}

pub fn route_to_string(route: Route) -> String {
  case route {
    Route(method:, path:, ..) ->
      { method |> method_to_string } <> " " <> { path |> path_to_string }
    InvalidRoute(file, line, cause) ->
      file <> "#" <> int.to_string(line) <> ": " <> cause
  }
}
