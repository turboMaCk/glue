module Subscriptions.Moves exposing (Model, Msg, init, subscriptions, update, view)

{-| This demostrates how subscription composition works with glueing.

Please be aware that this example was made just for purposes of this demonstration.

-}

import Html exposing (Html)


-- import Mouse exposing (Position)
-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Mouse.moves Moved
-- Model


type alias Position =
    { x : Int, y : Int }


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
            ( position
            , Cmd.none
            )



-- View


view : Model -> Html Msg
view model =
    Html.text <| "x: " ++ String.fromInt model.x ++ " y: " ++ String.fromInt model.y
