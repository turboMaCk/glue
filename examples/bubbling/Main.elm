module Bubbling.Main exposing (main)

import Html exposing (Html)


-- Library

import Component exposing (Component)


-- Components

import Bubbling.Counter as Counter


counter : Component Model Counter.Model Msg Counter.Msg
counter =
    Component.component
        { model = \subModel model -> { model | counter = subModel }
        , init = Counter.init Even
        , update = \subMsg model -> Counter.update Even subMsg model.counter
        , view = \model -> Counter.view CounterMsg model.counter
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
    { even : Bool
    , counter : Counter.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model False, Cmd.none )
        |> Component.init counter



-- Update


type Msg
    = CounterMsg Counter.Msg
    | Even


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( { model | even = False }, Cmd.none )
                |> Component.update counter counterMsg

        Even ->
            ( { model | even = True }, Cmd.none )



-- View


view : Model -> Html Msg
view model =
    Html.div []
        [ Component.view counter model
        , if model.even then
            Html.text "is even"
          else
            Html.text "is odd"
        ]
