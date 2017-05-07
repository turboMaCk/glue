module Glue
    exposing
        ( Glue
        , simple
        , poly
        , glue
        , init
        , update
        , view
        , subscriptions
        , map
        )

{-| Composing Elm applications from smaller isolated parts (modules).
You can think about this as about lightweight abstraction built around `(model, Cmd msg)` pair
that reduces boilerplate required for composing `init` `update` `view` and `subscribe` using
[`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Cmd#map),
[`Sub.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Sub#map)
and [`Html.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map).

# Datatype Definition

@docs Glue

# Constructors

@docs simple, poly, glue

# Basics

@docs init, update, view, subscriptions

# Helpers

@docs map

-}

import Html exposing (Html)


{-| `Glue` defines interface mapings between parent and child module.

You can create `Glue` with the [`glue`](#glue) function constructor.
Every glue layer is defined in terms of `Model`, `[Submodule].Model` `Msg` and `[Submodule].Msg`.
-}
type Glue model subModel msg subMsg
    = Glue
        { model : subModel -> model -> model
        , init : ( subModel, Cmd msg )
        , update : subMsg -> model -> ( subModel, Cmd msg )
        , view : model -> Html msg
        , subscriptions : model -> Sub msg
        }


{-| Create simple [Glue](#Glue) mappig between modules.

**Interface:**

```
simple :
    { msg : subMsg -> msg
    , accessModel : model -> subModel
    , updateModel : subModel -> model -> model
    , init : ( subModel, Cmd subMsg )
    , update : subMsg -> subModel -> ( subModel, Cmd subMsg )
    , view : subModel -> Html subMsg
    , subscriptions : subModel -> Sub subMsg
    }
    -> Glue model subModel msg subMsg
```
-}
simple :
    { msg : subMsg -> msg
    , accessModel : model -> subModel
    , updateModel : subModel -> model -> model
    , init : ( subModel, Cmd subMsg )
    , update : subMsg -> subModel -> ( subModel, Cmd subMsg )
    , view : subModel -> Html subMsg
    , subscriptions : subModel -> Sub subMsg
    }
    -> Glue model subModel msg subMsg
simple { msg, accessModel, updateModel, init, update, view, subscriptions } =
    Glue
        { model = updateModel
        , init = init |> map msg
        , update =
            \subMsg model ->
                accessModel model
                    |> update subMsg
                    |> map msg
        , view =
            \model ->
                accessModel model
                    |> view
                    |> Html.map msg
        , subscriptions =
            \model ->
                accessModel model
                    |> subscriptions
                    |> Sub.map msg
        }


{-| Crate polymorphic [Glue](#Glue) mapping between modules.

**Interface:**

```
poly :
    { msg : subMsg -> msg
    , accessModel : model -> subModel
    , updateModel : subModel -> model -> model
    , init : ( subModel, Cmd msg )
    , update : subMsg -> subModel -> ( subModel, Cmd msg )
    , view : subModel -> Html msg
    , subscriptions : subModel -> Sub msg
    }
    -> Glue model subModel msg subMsg
```
-}
poly :
    { msg : subMsg -> msg
    , accessModel : model -> subModel
    , updateModel : subModel -> model -> model
    , init : ( subModel, Cmd msg )
    , update : subMsg -> subModel -> ( subModel, Cmd msg )
    , view : subModel -> Html msg
    , subscriptions : subModel -> Sub msg
    }
    -> Glue model subModel msg subMsg
poly { msg, accessModel, updateModel, init, update, view, subscriptions } =
    Glue
        { model = updateModel
        , init = init
        , update =
            \subMsg model ->
                accessModel model
                    |> update subMsg
        , view =
            \model ->
                accessModel model
                    |> view
        , subscriptions =
            \model ->
                accessModel model
                    |> subscriptions
        }


{-| Create [Glue](#Glue) mapigs between modules.
child module can be generic TEA app or module that is already doing polymorfic maping to generic `msg` internaly.
You can also use `Cmd` for sending data from bottom module to upper one if you want to observe child
as a black box (similary you do in case of DOM events with `Html.Events`).

**Interface:**

```
glue :
    { model : subModel -> model -> model
    , init : ( subModel, Cmd msg )
    , update : subMsg -> model -> ( subModel, Cmd msg )
    , view : model -> Html msg
    , subscriptions : model -> Sub msg
    }
    -> Glue model subModel msg subMsg
```
-}
glue :
    { model : subModel -> model -> model
    , init : ( subModel, Cmd msg )
    , update : subMsg -> model -> ( subModel, Cmd msg )
    , view : model -> Html msg
    , subscriptions : model -> Sub msg
    }
    -> Glue model subModel msg subMsg
glue =
    Glue



-- Basics


{-| Initialize child module in parent.

```
type alias Model =
    { message : String
    , firstCounterModel : Counter.Model
    , secondCounterModel : Counter.Model
    }

init : ( Model, Cmd msg )
init =
    ( Model "", Cmd.none )
        |> Glue.init firstCounter
        |> Glue.init secondCounter
```
-}
init : Glue model subModel msg subMsg -> ( subModel -> a, Cmd msg ) -> ( a, Cmd msg )
init (Glue { init }) ( fc, cmd ) =
    let
        ( subModel, subCmd ) =
            init
    in
        ( fc subModel, Cmd.batch [ cmd, subCmd ] )


{-| Update submodule's state using it's `update` function.

```
type Msg
    = CounterMsg Counter.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( { model | message = "Counter has changed" }, Cmd.none )
                |> Glue.update counter counterMsg
```

-}
update : Glue model subModel msg subMsg -> subMsg -> ( model, Cmd msg ) -> ( model, Cmd msg )
update (Glue { update, model }) subMsg ( m, cmd ) =
    let
        ( subModel, subCmd ) =
            update subMsg m
    in
        ( model subModel m, Cmd.batch [ subCmd, cmd ] )


{-| Render submodule's view.

```
view : Model -> Html msg
view model =
    Html.div []
        [ Html.text model.message
        , Glue.view counter model
        ]
```
-}
view : Glue model subModel msg subMsg -> model -> Html msg
view (Glue { view }) =
    view


{-| Subscribe to subscriptions defined in submodule.

```
subscriptions : Model -> Sub Msg
subscriptions =
    (\model -> Mouse.clicks Clicked)
        |> Glue.subscriptions subModlue
        |> Glue.subscriptions anotherNestedModule
```
-}
subscriptions : Glue model subModel msg subMsg -> (model -> Sub msg) -> (model -> Sub msg)
subscriptions (Glue { subscriptions }) mainSubscriptions =
    \model -> Sub.batch [ mainSubscriptions model, subscriptions model ]



-- Helpers


{-| Tiny abstraction over [`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Cmd#map)
packed in `(model, Cmd msg)` pair that helps you to reduce boilerplate while turning generic TEA app to [`Glue`](#Glue) using [`glue`](#glue) constructor.

This function is generally usefull for turning update and init functions in [`Glue`](#glue) definition.

```
type alias Model =
    { message : String
    , counter : Counter.Model
    }

type Msg
    = CounterMsg Counter.Msg

-- this works liske `simple` constructor
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
```
-}
map : (subMsg -> msg) -> ( subModel, Cmd subMsg ) -> ( subModel, Cmd msg )
map constructor ( subModel, subCmd ) =
    ( subModel, Cmd.map constructor subCmd )
