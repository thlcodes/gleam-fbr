import errors
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile
import snag.{type Result}
import types.{type Route, Route}

import consts.{initial_template}

pub fn generate(
  from routes: List(Route),
  into file: String,
  force override: Bool,
) -> Result(String) {
  use current_content <- result.try(current_content(file, override))
  let route_cases = generate_route_cases(routes)
  let imports = generate_imports(routes)

  inject(current_content, route_cases, imports)
}

fn current_content(from path: String, force override: Bool) {
  case simplifile.read(path) {
    Ok(content) ->
      case override, was_generated_by_fbr(content) {
        _, True -> Ok(content)
        True, False -> Ok(initial_template)
        False, False -> snag.error(path <> " was not generated by me")
      }
    Error(simplifile.Enoent) -> Ok(initial_template)
    Error(err) -> errors.map_file_error(Error(err), "could not read " <> path)
  }
}

fn generate_route_cases(for routes: List(Route)) -> List(String) {
  list.map(routes, fn(route) {
    let assert Route(method:, path:, has_context:, ..) = route
    let method = case method {
      types.AnyMethod -> "_"
      types.Method(method) -> string.inspect(method)
    }
    let segments =
      "["
      <> list.filter_map(path, fn(segment) {
        case segment {
          types.Index -> Error(Nil)
          types.Static(static) -> Ok("\"" <> static <> "\"")
          types.Variable(var) -> Ok(var)
          types.Rest(rest) -> Ok("\"" <> rest <> "\", ..rest")
        }
      })
      |> string.join(", ")
      <> "]"
    let import_ = "routes_" <> path_segments(path) |> string.join("_")
    let first_params = case has_context {
      True -> ["req", "ctx"]
      False -> ["req"]
    }
    let params =
      list.concat([
        first_params,
        list.filter_map(path, fn(segment) {
          case segment {
            types.Variable(var) -> Ok(var)
            types.Rest(_) -> Ok("rest")
            _ -> Error(Nil)
          }
        }),
      ])
      |> string.join(", ")

    "http."
    <> method
    <> ", "
    <> segments
    <> " -> "
    <> import_
    <> "."
    <> string.lowercase(method)
    <> "("
    <> params
    <> ")"
  })
}

fn generate_imports(for routes: List(Route)) -> List(String) {
  list.map(routes, fn(route) {
    let assert Route(path:, ..) = route
    let segments = path_segments(path)
    "import routes/"
    <> string.join(segments, "/")
    <> " as routes_"
    <> string.join(segments, "_")
  })
  |> list.unique
  |> list.sort(string.compare)
}

fn path_segments(path: types.Path) {
  list.map(path, fn(segment) {
    case segment {
      types.Index -> "index"
      types.Static(static) -> static
      types.Variable(var) -> var <> "_"
      types.Rest(rest) -> rest <> "__"
    }
  })
}

type Markers {
  ImportsBegin
  ImportsEnd
  RoutesBegin
  RoutesEnd
}

fn inject(
  into content: String,
  cases cases: List(String),
  imports imports: List(String),
) -> Result(String) {
  let lines = string.split(content, "\n")

  let markers =
    lines
    |> list.index_map(fn(line, i) {
      case string.trim(line) {
        "// _FBR_IMPORTS_BEGIN_" -> Some(#(ImportsBegin, i))
        "// _FBR_IMPORTS_END_" -> Some(#(ImportsEnd, i))
        "// _FBR_ROUTES_BEGIN_" -> Some(#(RoutesBegin, i))
        "// _FBR_ROUTES_END_" -> Some(#(RoutesEnd, i))
        _ -> None
      }
    })
    |> option.values

  use marker_positions <- result.try(case markers {
    [
      #(ImportsBegin, ib),
      #(ImportsEnd, ie),
      #(RoutesBegin, rb),
      #(RoutesEnd, re),
    ] -> Ok([ib, ie, rb, re])
    _ -> Error(snag.new("invalid markers"))
  })

  let assert [ib, ie, rb, re] = marker_positions

  let pre_import_content = list.take(lines, ib + 1)
  let post_routes_content = list.drop(lines, re)
  let inner = list.take(lines, rb + 1) |> list.drop(ie)

  let cases = list.map(cases, fn(line) { "    " <> line })

  let new_lines =
    list.concat([
      pre_import_content,
      imports,
      [""],
      inner,
      cases,
      post_routes_content,
    ])

  let new_content = string.join(new_lines, "\n")
  Ok(new_content)
}

fn was_generated_by_fbr(content: String) -> Bool {
  string.contains(content, "_FBR_IMPORTS_BEGIN_")
  && string.contains(content, "_FBR_IMPORTS_END_")
  && string.contains(content, "_FBR_ROUTES_BEGIN_")
  && string.contains(content, "_FBR_ROUTES_END_")
}
