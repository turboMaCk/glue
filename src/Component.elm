module Component exposing (Component, component, init, update, view, subscriptions, lift)

{-| Composing Elm applications from smaller parts (Components) with respect to TEA.
You can think about this as about lightweight abstraction built around [`Html.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map)
and [`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Cmd#map)
that reduces boilerplate while composing TEA based components in larger applications.

# Types
@docs Component, component

# Basics
Interface with TEA parts.

@docs init, update, view, subscriptions

# Helpers
Helpers for transfering generic TEA application to [`Component`](#Component)

@docs lift

-}

import Html exposing (Html)


{-| A `Component` defines glue between sub-component and root component.

You can create `Component` with the [`component`](#component) constructor.
Every component is defined in terms of `Model`, `[SubComponent].Model` `Msg` and `[SubComponent].Msg`
in root component. `Component` is semanticaly similar to [`Html.Program`](http://package.elm-lang.org/packages/elm-lang/core/latest/Platform#Program).
-}
type Component model subModel msg subMsg
    = Component
        { model : subModel -> model -> model
        , init : ( subModel, Cmd msg )
        , update : subMsg -> model -> ( subModel, Cmd msg )
        , view : model -> Html msg
        , subscriptions : model -> Sub msg
        }


{-| Create [Component](#Component) from any TEA frendly app.
This defines interface between two parts of application.
Subcomponent can be generic TEA app or polymorphic component (One maping it's `Msg` internally).
You can also used `Cmd` for sending data from bottom component to upper one.

**Interface**:

```
component :
    { model : subModel -> model -> model
    , init : ( subModel, Cmd msg )
    , update : subMsg -> model -> ( subModel, Cmd msg )
    , view : model -> Html msg
    , subscriptions : model -> Sub msg
    }
    -> Component model subModel msg subMsg
```

See [examples](https://github.com/turboMaCk/component/tree/master/examples) for more informations.
-}
component :
    { model : subModel -> model -> model
    , init : ( subModel, Cmd msg )
    , update : subMsg -> model -> ( subModel, Cmd msg )
    , view : model -> Html msg
    , subscriptions : model -> Sub msg
    }
    -> Component model subModel msg subMsg
component =
    Component



-- Basics


{-| Initialize sub-component in parent component.

Init uses [applicative style](https://wiki.haskell.org/Applicative_functor) for `(a, Cmd Msg)`
similarly to [`Json.Decode.Extra.andMap`](http://package.elm-lang.org/packages/elm-community/json-extra/2.1.0/Json-Decode-Extra#andMap).
The only diference is that `( subModel, Cmd msg )` is extracted from [`Component`](#Component) definition.

```
type alias Model =
    { message : String
    , firstCounterModel : Counter.Model
    , secondCounterModel : Counter.Model
    }

init : ( Model, Cmd msg )
init =
    ( Model "I <3 TEA", Cmd.none )
        |> Component.init firstCounter
        |> Component.init secondCounter
```
-}
init : Component model subModel msg subMsg -> ( subModel -> a, Cmd msg ) -> ( a, Cmd msg )
init (Component { init }) ( fc, cmd ) =
    let
        ( subModel, subCmd ) =
            init
    in
        ( fc subModel, Cmd.batch [ cmd, subCmd ] )


{-| Update subComponent in parent's update

This uses [functor-like](https://en.wikipedia.org/wiki/Functor) approach to transform `(subModel, msg) -> (model, msg)`.
Anyway rather then using low level function like `map` this transformation is constructed from `model` and `update`
functions from [`Component`](#Component) for you under the hood.

```
type Msg
    = CounterMsg Counter.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CounterMsg counterMsg ->
            ( { model | message = "Hacking Elm" }, Cmd.none )
                |> Component.update counter counterMsg
```

-}
update : Component model subModel msg subMsg -> subMsg -> ( model, Cmd msg ) -> ( model, Cmd msg )
update (Component { update, model }) subMsg ( m, cmd ) =
    let
        ( subModel, subCmd ) =
            update subMsg m
    in
        ( model subModel m, Cmd.batch [ subCmd, cmd ] )


{-| Render sub-component's view within parent component.

This is in fact just proxy to `view` function from [`Component`](#Component). This function relies on [`Html.map`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#map)
and is efectively just wrapper around [functorish](https://en.wikipedia.org/wiki/Functor) operation.

```
view : Model -> Html msg
view model =
    Html.div []
        [ Html.text model.message
        , Component.view counter model
        ]
```

-}
view : Component model subModel msg subMsg -> model -> Html msg
view (Component { view }) =
    view


{-| Subscribe to sub component subscriptions within parent component.

You can think about this as about mapping and merging subscriptions.
For mapping `subscriptions` function from [`Component`](#Component) is used

```
subscriptions : Model -> Sub Msg
subscriptions model =
    Mouse.clicks Clicked


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions =
            subscriptions
                |> Component.subscriptions subComponent
                |> Component.subscriptions anotherNestedComponent
        }
```
-}
subscriptions : Component model subModel msg subMsg -> (model -> Sub msg) -> (model -> Sub msg)
subscriptions (Component { subscriptions }) mainSubscriptions =
    \model -> Sub.batch [ mainSubscriptions model, subscriptions model ]



-- Helpers


{-| Tiny abstraction over [`Cmd.map`](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Cmd#map)
that helps you to reduce boiler plate while turning generic TEA app to [`Component`](#Component).

This thing is generally usefull when turning independent elm applications to [`Component`](#Component)s.

```
type alias Model =
    { message : String
    , counter : Counter.Model
    }

type Msg
    = CounterMsg Counter.Msg

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
```
-}
lift : (subMsg -> msg) -> ( subModel, Cmd subMsg ) -> ( subModel, Cmd msg )
lift constructor ( subModel, subCmd ) =
    ( subModel, Cmd.map constructor subCmd )
