import context.{Context}
import gleam/http
import wisp

// _FBR_IMPORTS_BEGIN_
import routes/index as routes_index
import routes/joke as routes_joke
import routes/static__ as routes_static__
import routes/users/index as routes_users_index
import routes/users/user_ as routes_users_user_
import routes/users/user_/rate/rating_ as routes_users_user__rate_rating_

// _FBR_IMPORTS_END_

pub fn route(req: wisp.Request) -> wisp.Response {
  let ctx = Context("this is not a joke")
  use <- wisp.log_request(req)
  case req.method, wisp.path_segments(req) {
    // _FBR_ROUTES_BEGIN_
    http.Get, ["joke"] -> routes_joke.get(req, ctx)
    http.Post, ["joke"] -> routes_joke.post(req)
    http.Get, ["static", ..rest] -> routes_static__.get(req, rest)
    http.Get, [] -> routes_index.get(req)
    http.Get, ["users", user] -> routes_users_user_.get(req, user)
    http.Get, ["users"] -> routes_users_index.get(req)
    http.Get, ["users", user, "rate", rating] -> routes_users_user__rate_rating_.get(req, ctx, user, rating)
    // _FBR_ROUTES_END_
    _, _ -> not_found()
  }
}

fn not_found() -> wisp.Response {
  wisp.not_found() |> wisp.string_body("not_found")
}
