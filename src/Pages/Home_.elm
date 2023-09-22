module Pages.Home_ exposing (Model, Msg, page)

import Dict exposing (Dict)
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes
import Html.Events
import Http
import Markdown
import Page exposing (Page)
import Route exposing (Route)
import Set exposing (Set)
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { blocks : List Block
    , values : Dict Id String
    , readonlyBlocks : Set Id
    }


type alias Id =
    Int


init : () -> ( Model, Effect Msg )
init () =
    ( { blocks = []
      , values = Dict.empty
      , readonlyBlocks = Set.empty
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = ClickedNewMarkdownBlock
    | ClickedNewReplBlock
    | UpdatedBlockContent Id String
    | ClickedSaveMarkdown Id
    | ClickedEditMarkdown Id
    | ClickedRunElmCode Id String
    | ElmCompilerResponded Id (Result Http.Error CompilerData)


type alias CompilerData =
    String


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ClickedNewMarkdownBlock ->
            ( { model | blocks = model.blocks ++ [ MarkdownBlock ] }
            , Effect.none
            )

        ClickedNewReplBlock ->
            ( { model | blocks = model.blocks ++ [ ReplBlock ] }
            , Effect.none
            )

        UpdatedBlockContent id str ->
            ( { model | values = Dict.insert id str model.values }
            , Effect.none
            )

        ClickedSaveMarkdown id ->
            ( { model | readonlyBlocks = Set.insert id model.readonlyBlocks }
            , Effect.none
            )

        ClickedEditMarkdown id ->
            ( { model | readonlyBlocks = Set.remove id model.readonlyBlocks }
            , Effect.none
            )

        ClickedRunElmCode id elmCode ->
            ( model
            , Effect.sendToElmCompiler
                { elmCode = elmCode
                , onResponse = ElmCompilerResponded id
                }
            )

        ElmCompilerResponded id result ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Pages.Home_"
    , body =
        [ h1 [] [ text "Elm Notebook" ]
        , viewDocument model
        ]
    }


viewDocument : Model -> Html Msg
viewDocument model =
    div []
        [ viewControls
        , div []
            (List.indexedMap
                (viewBlock model)
                model.blocks
            )
        , viewControls
        ]


viewControls : Html Msg
viewControls =
    div []
        [ button [ Html.Events.onClick ClickedNewMarkdownBlock ]
            [ text "New markdown block" ]
        , button [ Html.Events.onClick ClickedNewReplBlock ]
            [ text "New REPL block" ]
        ]


type Block
    = MarkdownBlock
    | ReplBlock


viewBlock : Model -> Id -> Block -> Html Msg
viewBlock model id block =
    case block of
        MarkdownBlock ->
            let
                markdown : String
                markdown =
                    Dict.get id model.values
                        |> Maybe.withDefault ""

                isMarkdownReadonly : Bool
                isMarkdownReadonly =
                    Set.member id model.readonlyBlocks

                viewMarkdownEditUi : Html Msg
                viewMarkdownEditUi =
                    div []
                        [ textarea
                            [ Html.Events.onInput (UpdatedBlockContent id)
                            , Html.Attributes.value markdown
                            ]
                            []
                        , button [ Html.Events.onClick (ClickedSaveMarkdown id) ] [ text "Save" ]
                        ]

                viewRenderedMarkdown : Html Msg
                viewRenderedMarkdown =
                    div []
                        [ Markdown.toHtml [] markdown
                        , button [ Html.Events.onClick (ClickedEditMarkdown id) ] [ text "Edit" ]
                        ]
            in
            if isMarkdownReadonly then
                viewRenderedMarkdown

            else
                viewMarkdownEditUi

        ReplBlock ->
            let
                elmCode : String
                elmCode =
                    Dict.get id model.values
                        |> Maybe.withDefault ""
            in
            div []
                [ textarea
                    [ Html.Events.onInput (UpdatedBlockContent id)
                    , Html.Attributes.value elmCode
                    ]
                    []
                , button
                    [ Html.Events.onClick (ClickedRunElmCode id elmCode)
                    ]
                    [ text "Run" ]
                ]
