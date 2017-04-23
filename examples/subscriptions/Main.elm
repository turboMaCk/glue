module Subscriptions.Main exposing (main)

import Html exposing (Html)
import Mouse exposing (Position)


-- Library

import Glue exposing (Glue)


-- Submodules

import Subscriptions.Moves as Moves


moves : Glue Model Moves.Model Msg Moves.Msg
moves =
    Glue.glue
        { model = \subModel model -> { model | moves = subModel }
        , init = Moves.init |> Glue.map MovesMsg
        , update =
            \subMsg model ->
                Moves.update subMsg model.moves
                    |> Glue.map MovesMsg
        , view = \model -> Html.map MovesMsg <| Moves.view model.moves
        , subscriptions = \model -> Sub.map MovesMsg <| Moves.subscriptions model.moves
        }



-- Main


subscriptions : Model -> Sub Msg
subscriptions model =
    Mouse.clicks Clicked


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions =
            subscriptions
                |> Glue.subscriptions moves
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
