module Counter.Main exposing (main)

import Html exposing (Html)


-- Library

import Glue exposing (Glue)


-- Submodules

import Counter.Counter as Counter


counter : Glue Model Counter.Model Msg Counter.Msg
counter =
    Glue.glue
        { model = \subModel model -> { model | counter = subModel }
        , init = Counter.init |> Glue.map CounterMsg
        , update =
            \subMsg model ->
                Counter.update subMsg model.counter
                    |> Glue.map CounterMsg
        , view = \model -> Html.map CounterMsg <| Counter.view model.counter
        , subscriptions = \_ -> Sub.none
        }



-- Main


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions =
            subscriptions
                |> Glue.subscriptions counter
        }



-- Model


type alias Model =
    { message : String
    , counter : Counter.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model "Let's change cunter!", Cmd.none )
        |> Glue.init counter



-- Update


type Msg
    = CounterMsg Counter.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( { model | message = "Counter has changed!" }, Cmd.none )
                |> Glue.update counter counterMsg



-- View


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.text model.message
        , Glue.view counter model
        ]
