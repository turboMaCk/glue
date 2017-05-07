module Counter.Main exposing (Model, Msg, init, update, view, subscriptions)

import Html exposing (Html)


-- Library

import Glue exposing (Glue)


-- Submodules

import Counter.Counter as Counter


counter : Glue Model Counter.Model Msg Counter.Msg
counter =
    Glue.simple
        { msg = CounterMsg
        , accessModel = .counter
        , updateModel = \subModel model -> { model | counter = subModel }
        , init = Counter.init
        , update = Counter.update
        , view = Counter.view
        , subscriptions = \_ -> Sub.none
        }



-- Main


subscriptions : Model -> Sub Msg
subscriptions =
    (\_ -> Sub.none)
        |> Glue.subscriptions counter


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
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
