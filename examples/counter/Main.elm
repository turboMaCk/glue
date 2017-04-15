module Counter.Main exposing (main)

import Html exposing (Html)


-- Library

import Component exposing (Component)


-- Components

import Counter.Counter as Counter


counter : Component Model Counter.Model Msg Counter.Msg
counter =
    Component.component
        { model = \subModel model -> { model | counter = subModel }
        , init = Counter.init |> Component.lift CounterMsg
        , update =
            \subMsg model ->
                Counter.update subMsg model.counter
                    |> Component.lift CounterMsg
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
                |> Component.subscriptions counter
        }



-- Model


type alias Model =
    { message : String
    , counter : Counter.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model "Let's change cunter!", Cmd.none )
        |> Component.init counter



-- Update


type Msg
    = CounterMsg Counter.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( { model | message = "Counter has changed!" }, Cmd.none )
                |> Component.update counter counterMsg



-- View


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.text model.message
        , Component.view counter model
        ]
