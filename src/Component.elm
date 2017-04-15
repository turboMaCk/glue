module Component exposing (Component, component, init, update, view, subscriptions, lift)

import Html exposing (Html)


type alias Settings model subModel msg subMsg =
    { model : subModel -> model -> model
    , init : ( subModel, Cmd msg )
    , update : subMsg -> model -> ( subModel, Cmd msg )
    , view : model -> Html msg
    , subscriptions : model -> Sub msg
    }


type Component model subModel msg subMsg
    = Component (Settings model subModel msg subMsg)


component : Settings model subModel msg subMsg -> Component model subModel msg subMsg
component =
    Component



-- Basics


init : Component model subModel msg subMsg -> ( subModel -> a, Cmd msg ) -> ( a, Cmd msg )
init (Component { init }) ( fc, cmd ) =
    let
        ( subModel, subCmd ) =
            init
    in
        ( fc subModel, Cmd.batch [ cmd, subCmd ] )


update : Component model subModel msg subMsg -> subMsg -> ( model, Cmd msg ) -> ( model, Cmd msg )
update (Component { update, model }) subMsg ( m, cmd ) =
    let
        ( subModel, subCmd ) =
            update subMsg m
    in
        ( model subModel m, Cmd.batch [ subCmd, cmd ] )


view : Component model subModel msg subMsg -> model -> Html msg
view (Component { view }) =
    view


subscriptions : Component model subModel msg subMsg -> (model -> Sub msg) -> (model -> Sub msg)
subscriptions (Component { subscriptions }) mainSubscriptions =
    \model -> Sub.batch [ mainSubscriptions model, subscriptions model ]



-- Helpers


lift : (subMsg -> msg) -> ( subModel, Cmd subMsg ) -> ( subModel, Cmd msg )
lift constructor ( subModel, subCmd ) =
    ( subModel, Cmd.map constructor subCmd )
