module Bubbling.Counter exposing (Model, Msg, init, update, view)

import Html exposing (Html)
import Html.Events
import Cmd.Extra


-- Model


type alias Model =
    Int


init : msg -> ( Model, Cmd msg )
init msg =
    let
        model =
            0
    in
        ( model, notifyEven msg model )



-- update


type Msg
    = Increment
    | Decrement


isEven : Int -> Bool
isEven num =
    num % 2 == 0


notifyEven : msg -> Model -> Cmd msg
notifyEven msg model =
    if isEven model then
        Cmd.Extra.perform msg
    else
        Cmd.none


update : msg -> Msg -> Model -> ( Model, Cmd msg )
update notify msg model =
    let
        newModel =
            case msg of
                Increment ->
                    model + 1

                Decrement ->
                    model - 1
    in
        ( newModel, notifyEven notify newModel )



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
