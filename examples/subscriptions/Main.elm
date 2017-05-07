module Subscriptions.Main exposing (Model, Msg, init, update, view, subscriptions)

import Html exposing (Html)
import Mouse exposing (Position)


-- Library

import Glue exposing (Glue)


-- Submodules

import Subscriptions.Moves as Moves


moves : Glue Model Moves.Model Msg Moves.Msg
moves =
    Glue.simple
        { msg = MovesMsg
        , accessModel = .moves
        , updateModel = \subModel model -> { model | moves = subModel }
        , init = Moves.init
        , update = Moves.update
        , view = Moves.view
        , subscriptions = Moves.subscriptions
        }



-- Main


subscriptions : Model -> Sub Msg
subscriptions =
    (\_ -> Mouse.clicks Clicked)
        |> Glue.subscriptions moves


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- Model


type alias Model =
    { clicks : Int
    , moves : Moves.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model 0, Cmd.none )
        |> Glue.init moves



-- Update


type Msg
    = Clicked Position
    | MovesMsg Moves.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MovesMsg movesMsg ->
            ( model, Cmd.none )
                |> Glue.update moves movesMsg

        Clicked _ ->
            ( { model | clicks = model.clicks + 1 }, Cmd.none )



-- View


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.text <| "Clicks: " ++ (toString model.clicks)
        , Html.div []
            [ Html.text "Position: "
            , Glue.view moves model
            ]
        ]
