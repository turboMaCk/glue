module Subscriptions.Main exposing (Model, Msg, init, subscriptions, update, view)

{-| This is example of slightly bit more complex management of subscriptions
between parent and child.
-}

-- import Browser exposing (Position)

import Glue exposing (Glue)
import Html exposing (Html)
import Html.Attributes as HtmlA
import Html.Events exposing (onCheck)
import Subscriptions.Moves as Moves
import Browser


moves : Glue Model Moves.Model Msg Moves.Msg Moves.Msg
moves =
    Glue.simple
        { msg = MovesMsg
        , get = .moves
        , set = \subModel model -> { model | moves = subModel }
        , init = \_ -> Moves.init
        , update = Moves.update
        , subscriptions = Moves.subscriptions
        }



-- Main


subscriptions : Model -> Sub Msg
subscriptions =
    (\_ -> Sub.none)
        |> Glue.subscriptionsWhen .movesOn moves


main : Program () Model Msg
main =
    Browser.element
        { init = always init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- Model


type alias Model =
    { clicks : Int
    , movesOn : Bool
    , moves : Moves.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model 0 True, Cmd.none )
        |> Glue.init moves



-- Update


type Msg
    = Clicked { x : Int, y : Int }
    | MovesMsg Moves.Msg
    | ToggleMoves Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MovesMsg movesMsg ->
            ( model, Cmd.none )
                |> Glue.update moves movesMsg

        Clicked _ ->
            ( { model | clicks = model.clicks + 1 }, Cmd.none )

        ToggleMoves bool ->
            ( { model | movesOn = bool }, Cmd.none )



-- View


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.text <| "Clicks: " ++ String.fromInt model.clicks
        , Html.label [ HtmlA.style "display" "block" ]
            [ Html.text "subscribe to mouse moves"
            , Html.input
                [ onCheck ToggleMoves
                , HtmlA.type_ "checkbox"
                , HtmlA.checked model.movesOn
                ]
                []
            ]
        , Html.div []
            [ Html.text "Position: "
            , Glue.view moves Moves.view model
            ]
        ]
