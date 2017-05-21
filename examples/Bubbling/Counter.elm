module Bubbling.Counter exposing (Model, Msg(..), init, update, view)

import Html exposing (Html)
import Html.Events
import Cmd.Extra


-- Model


type alias Model =
    Int


init : (Model -> msg) -> ( Model, Cmd msg )
init msg =
    let
        model =
            0
    in
        ( model, notify msg model )



-- update


type Msg
    = Increment
    | Decrement


notify : (Model -> msg) -> Model -> Cmd msg
notify msg model =
    Cmd.Extra.perform <| msg model


update : (Model -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update event msg model =
    let
        newModel =
            case msg of
                Increment ->
                    model + 1

                Decrement ->
                    model - 1
    in
        ( newModel, notify event newModel )



-- View


view : (Msg -> msg) -> Model -> Html msg
view msg model =
    Html.map msg <|
        Html.div
            []
            [ Html.button [ Html.Events.onClick Decrement ] [ Html.text "-" ]
            , Html.text <| toString model
            , Html.button [ Html.Events.onClick Increment ] [ Html.text "+" ]
            ]
