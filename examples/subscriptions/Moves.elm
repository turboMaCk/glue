module Subscriptions.Moves exposing (Model, Msg, init, update, view, subscriptions)

import Html exposing (Html)
import Mouse exposing (Position)


-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Mouse.moves Moved



-- Model


type alias Model =
    Position


init : ( Model, Cmd Msg )
init =
    ( { x = 0, y = 0 }, Cmd.none )



-- Update


type Msg
    = Moved Position


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Moved position ->
            position ! []



-- View


view : Model -> Html Msg
view model =
    Html.text <| toString model
