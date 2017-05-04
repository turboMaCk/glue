module Multiple.Main exposing (main)

import Html exposing (Html)
import Mouse exposing (Position)


-- Library

import Glue exposing (Glue)


-- Submodules

import Multiple.Counter as Counter
import Multiple.BubblingCounter as BubblingCounter
import Multiple.Moves as Moves


counter : Glue Model Counter.Model Msg Counter.Msg
counter =
    Glue.createglue
        { modelsetter = \subModel model -> { model | counter = subModel }
        , modelgetter = .counter
        , init = Counter.init
        , update = Counter.update
        , view = Counter.view
        , subscriptions = \_ -> Sub.none
        , liftmessage = CounterMsg
        }


counter2 : Glue Model Counter.Model Msg Counter.Msg
counter2 =
    Glue.createglue
        { modelsetter = \subModel model -> { model | counter2 = subModel }
        , modelgetter = .counter2
        , init = Counter.init
        , update = Counter.update
        , view = Counter.view
        , subscriptions = \_ -> Sub.none
        , liftmessage = Counter2Msg
        }


moves : Glue Model Moves.Model Msg Moves.Msg
moves =
    Glue.createglue
        { modelsetter = \subModel model -> { model | moves = subModel }
        , modelgetter = .moves
        , init = Moves.init
        , update = Moves.update
        , view = Moves.view
        , subscriptions = Moves.subscriptions
        , liftmessage = MovesMsg
        }



-- bubblingcounter has a non-standard type definition can't use createglue use glue instead


bubblingcounter : Glue Model BubblingCounter.Model Msg BubblingCounter.Msg
bubblingcounter =
    Glue.glue
        { model = \subModel model -> { model | bubblingcounter = subModel }
        , init = BubblingCounter.init Even
        , update = \subMsg model -> BubblingCounter.update Even subMsg model.bubblingcounter
        , view = \model -> BubblingCounter.view BubblingCounterMsg model.bubblingcounter
        , subscriptions = \_ -> Sub.none
        }



-- Main


localsubscriptions : Model -> Sub Msg
localsubscriptions model =
    Mouse.clicks Clicked


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions =
    localsubscriptions
        |> Glue.subscriptions counter
        |> Glue.subscriptions counter2
        |> Glue.subscriptions moves
        |> Glue.subscriptions bubblingcounter


counterlist : List (Glue Model Counter.Model Msg Counter.Msg)
counterlist =
    [ counter, counter2 ]



-- Model


type alias Model =
    { message : String
    , clicks : Int
    , even : Bool
    , moves : Moves.Model
    , bubblingcounter : BubblingCounter.Model
    , counter : Counter.Model
    , counter2 : Counter.Model
    }


init : ( Model, Cmd Msg )
init =
    ( Model "Let's change cunter!" 0 False
    , Cmd.none
    )
        |> Glue.init moves
        |> Glue.init bubblingcounter
        |> Glue.init counter
        |> Glue.init counter2



-- Update


type Msg
    = CounterMsg Counter.Msg
    | Counter2Msg Counter.Msg
    | Clicked Position
    | MovesMsg Moves.Msg
    | BubblingCounterMsg BubblingCounter.Msg
    | Even


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( { model | message = "Counter has changed!" }, Cmd.none )
                |> Glue.update counter counterMsg

        MovesMsg movesMsg ->
            ( model, Cmd.none )
                |> Glue.update moves movesMsg

        Clicked _ ->
            ( { model | clicks = model.clicks + 1 }, Cmd.none )

        BubblingCounterMsg bubblingcounterMsg ->
            ( { model | even = False }, Cmd.none )
                |> Glue.update bubblingcounter bubblingcounterMsg

        Even ->
            ( { model | even = True }, Cmd.none )

        Counter2Msg counterMsg ->
            ( model, Cmd.none )
                |> Glue.update counter2 counterMsg



-- View


view : Model -> Html Msg
view model =
    Html.div []
        [ counterview model
        , movesview model
        , bubblingcounterview model
        , counter2view model
        ]


movesview : Model -> Html Msg
movesview model =
    Html.div []
        [ Html.text <| "Clicks: " ++ (toString model.clicks)
        , Html.div []
            [ Html.text "Position: "
            , Glue.view moves model
            ]
        ]


counterview : Model -> Html Msg
counterview model =
    Html.div []
        [ Html.text model.message
        , Glue.view counter
            model
        ]


counter2view : Model -> Html Msg
counter2view model =
    Html.div []
        [ Glue.view counter2
            model
        ]


bubblingcounterview : Model -> Html Msg
bubblingcounterview model =
    Html.div []
        [ Glue.view bubblingcounter model
        , if model.even then
            Html.text "is even"
          else
            Html.text "is odd"
        ]
