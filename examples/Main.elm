module Main exposing (..)

import Html exposing (..)
import Glue exposing (Glue)


-- Sub Modules

import Counter.Main as Counter
import Bubbling.Main as Bubbling
import Subscriptions.Main as Subscriptions


counter : Glue Model Counter.Model Msg Counter.Msg
counter =
    Glue.simple
        { msg = CounterMsg
        , accessModel = .counterModel
        , updateModel = \sm m -> { m | counterModel = sm }
        , init = Counter.init
        , update = Counter.update
        , view = Counter.view
        , subscriptions = Counter.subscriptions
        }


bubbling : Glue Model Bubbling.Model Msg Bubbling.Msg
bubbling =
    Glue.simple
        { msg = BubblingMsg
        , accessModel = .bubblingModel
        , updateModel = \sm m -> { m | bubblingModel = sm }
        , init = Bubbling.init
        , update = Bubbling.update
        , view = Bubbling.view
        , subscriptions = Bubbling.subscriptions
        }


subscriptions : Glue Model Subscriptions.Model Msg Subscriptions.Msg
subscriptions =
    Glue.simple
        { msg = SubscriptionsMsg
        , accessModel = .subscriptionsModel
        , updateModel = \sm m -> { m | subscriptionsModel = sm }
        , init = Subscriptions.init
        , update = Subscriptions.update
        , view = Subscriptions.view
        , subscriptions = Subscriptions.subscriptions
        }



-- Model


type alias Model =
    { counterModel : Counter.Model
    , bubblingModel : Bubbling.Model
    , subscriptionsModel : Subscriptions.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model, Cmd.none )
        |> Glue.init counter
        |> Glue.init bubbling
        |> Glue.init subscriptions



-- Update


type Msg
    = CounterMsg Counter.Msg
    | BubblingMsg Bubbling.Msg
    | SubscriptionsMsg Subscriptions.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( model, Cmd.none )
                |> Glue.update counter counterMsg

        BubblingMsg bubblingMsg ->
            ( model, Cmd.none )
                |> Glue.update bubbling bubblingMsg

        SubscriptionsMsg subscriptionsMsg ->
            ( model, Cmd.none )
                |> Glue.update subscriptions subscriptionsMsg


view : Model -> Html Msg
view model =
    main_ []
        [ Glue.view counter model
        , Glue.view bubbling model
        , Glue.view subscriptions model
        ]



-- Subscriptions


subscriptions_ : Model -> Sub Msg
subscriptions_ =
    (\model -> Sub.none)
        |> Glue.subscriptions counter
        |> Glue.subscriptions bubbling
        |> Glue.subscriptions subscriptions



-- Main


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions_
        }
