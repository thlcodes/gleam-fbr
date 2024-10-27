import consts
import glance
import gleam/bool
import gleam/http
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string
import simplifile
import snag.{type Result}

import errors.{map_file_error}
import types.{
  type Method, type Path, type Route, AnyMethod, InvalidRoute, Method, Rest,
  Route, Static, Variable,
}

pub fn parse_route_files(files: List(String)) -> Result(List(Route)) {
  files |> list.try_map(parse_route_file) |> result.map(list.flatten)
}

fn parse_route_file(file: String) -> Result(List(Route)) {
  use content <- result.try(
    simplifile.read(file)
    |> map_file_error("could not read route file " <> file),
  )
  use module <- result.try(
    glance.module(content)
    |> result.map_error(fn(err) {
      snag.new("could not parse module: " <> string.inspect(err))
    }),
  )

  module.functions
  |> list.try_map(function_to_route(file, content, _))
  |> result.map(option.values)
}

fn function_to_route(
  file: String,
  content: String,
  func: glance.Definition(glance.Function),
) -> Result(Option(Route)) {
  let glance.Function(name, publicity, params, return, _, span) =
    func.definition

  // try to parse method
  use method <- result.try(
    parse_method(name) |> snag.context("could not parse method"),
  )

  // ignore when function is not public
  use <- bool.guard(publicity != glance.Public, Ok(None))

  let line = get_line_number_from_span(content, span)

  // check of return of function is wisp.Response
  use <- bool.guard(
    return != Some(glance.NamedType("Response", Some("wisp"), [])),
    Ok(Some(InvalidRoute(file, line, "does not return `wisp.Response`"))),
  )

  // check if first function param is wisp.Request
  use <- bool.guard(
    list.first(params)
    |> result.map(fn(param) {
      param.type_ == Some(glance.NamedType("Request", Some("wisp"), []))
    })
      != Ok(True),
    Ok(
      Some(InvalidRoute(file, line, "first param is not of type `wisp.Request`")),
    ),
  )

  let path = file_path_to_path(file)

  // check of number of function params matches number of path variables
  use <- bool.guard(
    get_num_fn_params_for_path(path) != { list.length(params) - 1 },
    Ok(
      Some(InvalidRoute(
        file,
        line,
        "number of function arguments (without first) does not match number of path variables",
      )),
    ),
  )

  // check if all params but the first are strings
  // TODO: support other types
  use <- bool.guard(
    list.rest(params)
      |> result.unwrap([])
      |> list.any(fn(param) {
        param.type_ != Some(glance.NamedType("String", None, []))
      }),
    Ok(
      Some(InvalidRoute(
        file,
        line,
        "function has path params that are not of type `String`",
      )),
    ),
  )

  Ok(Some(Route(file, line, method, path)))
}

fn file_path_to_path(path: String) -> Path {
  let assert Ok(replacer) = regex.from_string("(?:index)?(\\.gleam)")

  path
  |> regex.replace(replacer, _, "")
  |> string.drop_left(consts.routes_folder |> string.length)
  |> string.split("/")
  |> list.filter(fn(entry) { !string.is_empty(entry) })
  |> list.map(fn(entry) {
    case string.ends_with(entry, "__"), string.ends_with(entry, "_") {
      True, _ -> Rest(string.drop_right(entry, 2))
      False, True -> Variable(string.drop_right(entry, 1))
      _, _ -> Static(entry)
    }
  })
}

const supported_methods = [
  "get", "post", "put", "patch", "head", "delete", "trace", "connect",
]

fn parse_method(m: String) -> Result(Method) {
  case list.contains(supported_methods, m), m {
    _, "any" -> Ok(AnyMethod)
    True, _ ->
      http.parse_method(m)
      |> result.map(fn(m) { Method(m) })
      |> result.map_error(fn(_) { snag.new("unsupported method" <> m) })
    _, _ -> snag.error("unsupported method " <> m)
  }
}

fn get_line_number_from_span(content: String, span: glance.Span) -> Int {
  content
  |> string.slice(0, span.start)
  |> string.split("\n")
  |> list.length
  |> int.add(1)
}

// error helpers
// to_string methods

fn get_num_fn_params_for_path(path: Path) -> Int {
  path
  |> list.filter(fn(seg) {
    case seg {
      Variable(_) | Rest(_) -> True
      _ -> False
    }
  })
  |> list.length
}
